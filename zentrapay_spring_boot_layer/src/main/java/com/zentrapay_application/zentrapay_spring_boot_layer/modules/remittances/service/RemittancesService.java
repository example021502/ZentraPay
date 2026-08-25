package com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittances.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.ExchangeRateModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.FiatAccountModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.FiatWalletModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.GatewayCountryModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.GatewayCurrencyModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.RemittanceModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.TransactionModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ResourceNotFoundException;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittances.dtos.*;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Cross-border remittance business logic.
 * <p>
 * Hard rule #1: remittances are CROSS-BORDER ONLY. If the recipient resolves
 * to the sender's own registered country the flow is rejected up-front with
 * the explicit "same country" message — domestic transfers belong to
 * {@code POST /api/payments}.
 * <p>
 * Hard rule #2: both the destination country and every currency involved must
 * be present-and-active in the gateway directory tables
 * ({@code gateway_countries}/{@code gateway_currencies}).
 */
@Service
@RequiredArgsConstructor
public class RemittancesService {

    private static final String type_debit = "debit";
    private static final SecureRandom random = new SecureRandom();

    private final UserRepository userRepository;
    private final FiatWalletRepository fiatWalletRepository;
    private final FiatAccountRepository fiatAccountRepository;
    private final TransactionRepository transactionRepository;
    private final RemittancesRepository remittancesRepository;
    private final GatewayCountriesRepository gatewayCountriesRepository;
    private final GatewayCurrenciesRepository gatewayCurrenciesRepository;
    private final ExchangeRatesRepository exchangeRatesRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${app.pin.pepper}")
    private String pinPepper;

    /** Flat percentage fee on the source amount — overridable per environment. */
    @Value("${app.remit.fee-percent:1.0}")
    private BigDecimal feePercent;

    // QUOTE — pre-flight FX preview; no money moves, no PIN required.
    @Transactional(readOnly = true)
    public RemitQuoteResponseDTO quote(UUID senderId, RemitQuoteRequestDTO req) {
        UserModel sender = requireUser(senderId);
        String destinationCountryCode = normalise(req.destinationCountryCode());
        assertCrossBorder(sender, destinationCountryCode);

        GatewayCountryModel country = requireActiveCountry(destinationCountryCode);
        String destinationCurrencyCode = country.getCurrencyCode();
        assertCurrencySupported(normalise(req.sourceCurrencyCode()));
        assertCurrencySupported(destinationCurrencyCode);

        BigDecimal rate = resolveRate(normalise(req.sourceCurrencyCode()), destinationCurrencyCode);
        BigDecimal fee = feeFor(req.amount());

        return new RemitQuoteResponseDTO(
                normalise(req.sourceCurrencyCode()),
                destinationCurrencyCode,
                destinationCountryCode,
                rate,
                scale(req.amount()),
                scale(req.amount().multiply(rate)),
                fee,
                scale(req.amount().add(fee)));
    }

    // SEND — the actual cross-border transfer. Flat body, mirrors the
    // frontend RemittanceRepository.send payload one-to-one.
    @Transactional
    public RemitResponseDTO send(UUID senderId, RemitRequestDTO req) {
        UserModel sender = requireUser(senderId);

        if (!passwordEncoder.matches(req.pin() + pinPepper, sender.getTransactionPinHash())) {
            throw new IllegalArgumentException("Invalid PIN");
        }

        String destinationCountryCode = normalise(req.recipientCountryCode());
        String sourceCurrencyCode = normalise(req.sourceCurrencyCode());

        // CROSS-BORDER ONLY — reject domestic recipients with the explicit message.
        assertCrossBorder(sender, destinationCountryCode);

        GatewayCountryModel country = requireActiveCountry(destinationCountryCode);
        String destinationCurrencyCode = Optional.ofNullable(req.destinationCurrencyCode())
                .filter(code -> !code.isBlank())
                .map(this::normalise)
                .orElse(country.getCurrencyCode());
        if (!destinationCurrencyCode.equalsIgnoreCase(country.getCurrencyCode())) {
            throw new IllegalArgumentException(
                    "Payouts to " + destinationCountryCode.toUpperCase() + " settle in "
                            + country.getCurrencyCode() + ", not " + destinationCurrencyCode);
        }

        assertCurrencySupported(sourceCurrencyCode);
        assertCurrencySupported(destinationCurrencyCode);

        BigDecimal rate = resolveRate(sourceCurrencyCode, destinationCurrencyCode);
        BigDecimal amount = scale(req.amount());
        BigDecimal destinationAmount = scale(amount.multiply(rate));
        BigDecimal fee = feeFor(amount);

        // Debit the sender's source-currency account (amount + fee).
        FiatWalletModel senderWallet = fiatWalletRepository.getWalletByUserId(senderId)
                .orElseThrow(() -> new ResourceNotFoundException("User wallet not found"));
        FiatAccountModel senderAccount = fiatAccountRepository
                .getWalletByWalletIdAndCurrencyCode(senderWallet.getWalletId(), sourceCurrencyCode)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "You currently don't have a " + sourceCurrencyCode + " account. Please create one first"));
        if (!senderAccount.getStatus().equalsIgnoreCase("active")) {
            throw new IllegalArgumentException("Your account is " + senderAccount.getStatus() + " at the moment");
        }
        int debited = fiatAccountRepository.debit(senderWallet.getWalletId(), amount.add(fee), sourceCurrencyCode);
        if (debited == 0) {
            throw new IllegalArgumentException("Insufficient balance");
        }

        // Resolve an app-user receiver when possible (explicit id first, then
        // phone lookup) — non-app recipients are paid out via gateway channels.
        UUID receiverId = Optional.ofNullable(req.recipientUserId())
                .or(() -> userRepository.findByEmailOrPhoneNumber(null, req.recipientPhoneNumber())
                        .map(UserModel::getUserId))
                .orElse(null);

        return persistRemittance(sender, req, receiverId,
                amount, fee, rate, destinationAmount, sourceCurrencyCode, destinationCurrencyCode);
    }

    // HISTORY — the sender's past cross-border sends, newest first.
    @Transactional(readOnly = true)
    public List<RemitResponseDTO> history(UUID senderId) {
        requireUser(senderId);
        return remittancesRepository.findBySenderIdOrderByCreatedAtDesc(senderId).stream()
                .map(RemittancesService::toDTO)
                .toList();
    }

    // RATES — lightweight FX preview for the remittance picker. No sender
    // context required (no cross-border assertion here; that happens on send),
    // returns the resolved rate plus the fee for the requested amount.
    @Transactional(readOnly = true)
    public RemitQuoteResponseDTO rates(String sourceCurrencyCode, String destinationCurrencyCode, BigDecimal amount) {
        String source = normalise(sourceCurrencyCode);
        String destination = normalise(destinationCurrencyCode);
        BigDecimal safeAmount = amount == null || amount.compareTo(BigDecimal.ZERO) <= 0
                ? BigDecimal.valueOf(100)
                : scale(amount);

        assertCurrencySupported(source);
        assertCurrencySupported(destination);

        BigDecimal rate = resolveRate(source, destination);
        BigDecimal fee = feeFor(safeAmount);

        return new RemitQuoteResponseDTO(
                source,
                destination,
                "",
                rate,
                safeAmount,
                scale(safeAmount.multiply(rate)),
                fee,
                scale(safeAmount.add(fee)));
    }

    // ============================================================
    // PRIVATE HELPERS
    // ============================================================

    private UserModel requireUser(UUID userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }

    private String normalise(String value) {
        return value == null ? "" : value.trim();
    }

    /**
     * HARD RULE: remittances are cross-border only. A recipient in the
     * sender's own registered country is rejected with an explicit message
     * so the frontend can route the user to the domestic pay flow instead.
     */
    private void assertCrossBorder(UserModel sender, String destinationCountryCode) {
        if (destinationCountryCode.isEmpty()
                || destinationCountryCode.equalsIgnoreCase(sender.getCountryCode())) {
            throw new IllegalArgumentException(
                    "The receiver is within the same country as you. Cross-border remittance "
                            + "is only for recipients in another country — please use the Pay "
                            + "section for domestic transfers.");
        }
    }

    /** Destination country must be present AND active in the gateway directory. */
    private GatewayCountryModel requireActiveCountry(String countryCode) {
        return gatewayCountriesRepository.findFirstByCountryCode(countryCode)
                .filter(GatewayCountryModel::isActive)
                .orElseThrow(() -> new IllegalArgumentException(
                        "We currently don't support remittances to " + countryCode.toUpperCase()
                                + ". Please choose another destination country"));
    }

    /** Every currency involved must be present AND active in the gateway directory. */
    private void assertCurrencySupported(String currencyCode) {
        gatewayCurrenciesRepository.findById(currencyCode)
                .filter(GatewayCurrencyModel::isActive)
                .orElseThrow(() -> new IllegalArgumentException(
                        "We currently don't support " + currencyCode.toUpperCase()
                                + " transfers. Please choose another currency"));
    }

    /**
     * Latest published rate for the pair: direct row first, then the inverted
     * opposite-direction row, then USD triangulation — mirroring ConverterService.
     */
    private BigDecimal resolveRate(String sourceCurrencyCode, String destinationCurrencyCode) {
        if (sourceCurrencyCode.equalsIgnoreCase(destinationCurrencyCode)) {
            return BigDecimal.ONE;
        }

        Optional<ExchangeRateModel> direct = exchangeRatesRepository
                .findFirstByBaseCurrencyCodeIgnoreCaseAndQuoteCurrencyCodeIgnoreCaseOrderByEffectiveAtDesc(
                        sourceCurrencyCode, destinationCurrencyCode);
        if (direct.isPresent()) {
            return direct.get().getRate();
        }

        Optional<ExchangeRateModel> inverse = exchangeRatesRepository
                .findFirstByBaseCurrencyCodeIgnoreCaseAndQuoteCurrencyCodeIgnoreCaseOrderByEffectiveAtDesc(
                        destinationCurrencyCode, sourceCurrencyCode);
        if (inverse.isPresent() && inverse.get().getRate().compareTo(BigDecimal.ZERO) != 0) {
            return BigDecimal.ONE.divide(inverse.get().getRate(), 10, RoundingMode.HALF_UP);
        }

        Optional<ExchangeRateModel> baseToUsd = exchangeRatesRepository
                .findFirstByBaseCurrencyCodeIgnoreCaseAndQuoteCurrencyCodeIgnoreCaseOrderByEffectiveAtDesc(
                        sourceCurrencyCode, "USD");
        Optional<ExchangeRateModel> usdToQuote = exchangeRatesRepository
                .findFirstByBaseCurrencyCodeIgnoreCaseAndQuoteCurrencyCodeIgnoreCaseOrderByEffectiveAtDesc(
                        "USD", destinationCurrencyCode);
        if (baseToUsd.isPresent() && usdToQuote.isPresent()) {
            return baseToUsd.get().getRate().multiply(usdToQuote.get().getRate())
                    .setScale(10, RoundingMode.HALF_UP);
        }

        throw new IllegalArgumentException(
                "No exchange rate available for " + sourceCurrencyCode.toUpperCase() + " → "
                        + destinationCurrencyCode.toUpperCase() + " at the moment. Please try again later");
    }

    private BigDecimal scale(BigDecimal value) {
        return value.setScale(2, RoundingMode.HALF_UP);
    }

    private BigDecimal feeFor(BigDecimal amount) {
        return amount.multiply(feePercent).divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
    }

    private String generateReference() {
        String timestamp = LocalDateTime.now().toString().replaceAll("[^0-9]", "");
        String suffix = String.format("%04d", random.nextInt(10000));
        return "ZR_" + timestamp + "_" + suffix;
    }

    /**
     * Persists the sender-side debit leg in {@code transactions} plus the
     * {@code remittances} row itself. The receiver payout leg is created by
     * the gateway settlement hook once the channel confirms.
     */
    private RemitResponseDTO persistRemittance(UserModel sender, RemitRequestDTO req, UUID receiverId,
                                               BigDecimal amount, BigDecimal fee, BigDecimal rate,
                                               BigDecimal destinationAmount,
                                               String sourceCurrencyCode, String destinationCurrencyCode) {
        String reference = generateReference();

        TransactionModel debitLeg = new TransactionModel();
        debitLeg.setAmount(amount.add(fee));
        debitLeg.setGateway("internal");
        debitLeg.setStatus("success");
        debitLeg.setTransactionType(type_debit);
        debitLeg.setSenderId(sender.getUserId());
        debitLeg.setReceiverId(receiverId);
        debitLeg.setSenderName(sender.getFirstName() + sender.getLastName());
        debitLeg.setReceiverName(normalise(req.recipientName()));
        debitLeg.setSourceCurrencyCode(sourceCurrencyCode);
        debitLeg.setDestinationCurrencyCode(destinationCurrencyCode);
        debitLeg.setPurpose(Optional.ofNullable(req.purpose()).orElse("Cross-border remittance"));
        debitLeg.setSenderEmail(sender.getEmail());
        debitLeg.setSenderPhoneNumber(sender.getPhoneNumber());
        debitLeg.setReceiverEmail("");
        debitLeg.setReceiverPhoneNumber(normalise(req.recipientPhoneNumber()));
        debitLeg.setInternalReferenceId(reference);
        debitLeg.setExternalReferenceId(reference);
        debitLeg.setEntryId(reference);
        debitLeg.setDestinationIdentifier(normalise(req.recipientPhoneNumber()));
        debitLeg.setFailureReason("");
        TransactionModel savedDebit = transactionRepository.save(debitLeg);

        RemittanceModel remittance = new RemittanceModel();
        remittance.setSenderId(sender.getUserId());
        remittance.setReceiverId(receiverId);
        remittance.setTransactionId(savedDebit.getTransactionId());
        remittance.setAmount(amount);
        remittance.setSourceCurrencyCode(sourceCurrencyCode);
        remittance.setDestinationCurrencyCode(destinationCurrencyCode);
        remittance.setExchangeRate(rate);
        remittance.setFee(fee);
        remittance.setStatus("completed");
        remittance.setChannel(Optional.ofNullable(req.channel())
                .filter(c -> !c.isBlank())
                .orElse("mobile_money"));
        remittance.setRecipientName(normalise(req.recipientName()));
        remittance.setRecipientPhoneNumber(normalise(req.recipientPhoneNumber()));
        remittance.setRecipientCountryCode(normalise(req.recipientCountryCode()).toUpperCase());
        remittance.setReference(reference);
        remittancesRepository.save(remittance);

        return toDTO(remittance, destinationAmount);
    }

    private static RemitResponseDTO toDTO(RemittanceModel r, BigDecimal destinationAmount) {
        return new RemitResponseDTO(
                r.getRemittanceId(),
                r.getTransactionId(),
                r.getReference(),
                r.getRecipientName(),
                r.getRecipientCountryCode(),
                r.getSourceCurrencyCode(),
                r.getDestinationCurrencyCode(),
                r.getAmount(),
                destinationAmount,
                r.getExchangeRate(),
                r.getFee(),
                r.getStatus(),
                r.getChannel(),
                r.getCreatedAt());
    }

    /** History rows recompute the destination amount from the stored rate. */
    private static RemitResponseDTO toDTO(RemittanceModel r) {
        return toDTO(r, r.getAmount().multiply(r.getExchangeRate()).setScale(2, RoundingMode.HALF_UP));
    }
}