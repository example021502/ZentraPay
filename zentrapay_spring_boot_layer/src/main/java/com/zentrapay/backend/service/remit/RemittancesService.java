package com.zentrapay.backend.service.remit;

import com.zentrapay.backend.dto.remit.*;
import com.zentrapay.backend.entity.*;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.repository.*;
import com.zentrapay.backend.service.common.Datatypes;
import com.zentrapay.backend.service.common.NanoIdGenerator;
import com.zentrapay.backend.service.fx.ExchangeRateService;
import com.zentrapay.backend.service.payment.AccountVerificationService;
import com.zentrapay.backend.service.payment.BankTransferServices;
import com.zentrapay.backend.service.payment.LedgerOperations;
import com.zentrapay.backend.service.region.SupportedRegionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import com.zentrapay.backend.service.user.PinService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Cross-border remittance (ZRemit).
 *
 * <p>Rule 1: remittances are CROSS-BORDER ONLY. A recipient in the sender's own country is
 * rejected with an explicit message - domestic transfers belong to POST /api/payments/initialize.
 * <p>Rule 2: the destination country and both currencies must be active in the gateway
 * directory ({@code gateway_countries} / {@code gateway_currencies}).
 *
 * <p>A remittance can go to a registered ZentraPay user (wallet to wallet, the ledger handles the
 * currency conversion), to a bank account abroad, or to a mobile-money wallet abroad. The last two
 * use the cross-border payout route (Onafriq first, Flutterwave as the fallback) and are checked with
 * the payment providers BEFORE any money is debited.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class RemittancesService {

    private final UserRepository userRepository;
    private final FiatWalletRepository fiatWalletRepository;
    private final FiatAccountRepository fiatAccountRepository;
    private final RemittancesRepository remittancesRepository;
    private final GatewayCountriesRepository gatewayCountriesRepository;
    private final GatewayCurrenciesRepository gatewayCurrenciesRepository;
    private final ExchangeRateService exchangeRateService;
    private final LedgerOperations ledgerOperations;
    private final PinService pinService;
    private final SupportedRegionService supportedRegionService;
    private final AccountVerificationService accountVerificationService;
    private final BankTransferServices bankTransferServices;
    private final TransactionRepository transactionRepository;

    // Flat percentage fee on the source amount - overridable per environment
    @Value("${app.remit.fee-percent:1.0}")
    private BigDecimal feePercent;

    // ==================================================================
    // QUOTE - FX preview with the sender's country check; no money moves
    // ==================================================================

    @Transactional(readOnly = true)
    public RemitQuoteResponseDTO quote(UUID senderId, RemitQuoteRequestDTO req) {
        UserModel sender = requireUser(senderId);
        supportedRegionService.requireUserCountry(sender);
        String destinationCountryCode = normalise(req.destinationCountryCode());
        assertCrossBorder(sender, destinationCountryCode);

        GatewayCountryModel country = requireActiveCountry(destinationCountryCode);
        String source = normalise(req.sourceCurrencyCode());
        String destination = country.getCurrencyCode();
        assertCurrencySupported(source);
        assertCurrencySupported(destination);

        BigDecimal rate = exchangeRateService.rate(source, destination);
        BigDecimal fee = feeFor(req.amount());
        return new RemitQuoteResponseDTO(source, destination, destinationCountryCode, rate, scale(req.amount()),
                scale(req.amount().multiply(rate)), fee, scale(req.amount().add(fee)));
    }

    // ==================================================================
    // SEND - the actual cross-border transfer
    // ==================================================================

    public RemitResponseDTO send(UUID senderId, RemitRequestDTO req) {
        log.info("========== REMIT START: sender={} to {} ==========", senderId, req.recipientCountryCode());
        UserModel sender = requireUser(senderId);
        pinService.requireValid(sender, req.pin());
        supportedRegionService.requireUserCountry(sender);

        // Cross-border only, and only to supported countries / currencies
        String destinationCountryCode = normalise(req.recipientCountryCode());
        assertCrossBorder(sender, destinationCountryCode);
        GatewayCountryModel country = requireActiveCountry(destinationCountryCode);

        String sourceCurrency = normalise(req.sourceCurrencyCode()).toUpperCase();
        String destinationCurrency = Optional.ofNullable(req.destinationCurrencyCode())
                .filter(code -> !code.isBlank())
                .map(code -> normalise(code).toUpperCase())
                .orElse(country.getCurrencyCode());
        if (!destinationCurrency.equalsIgnoreCase(country.getCurrencyCode())) {
            throw new IllegalArgumentException("Payouts to " + destinationCountryCode.toUpperCase()
                    + " settle in " + country.getCurrencyCode() + ", not " + destinationCurrency);
        }
        assertCurrencySupported(sourceCurrency);
        assertCurrencySupported(destinationCurrency);

        String recipientType = recipientTypeOf(req);
        if (!"USER".equals(recipientType)) {
            return sendToExternal(sender, req, recipientType, destinationCountryCode, sourceCurrency, destinationCurrency);
        }

        // The receiver must be a ZentraPay user in that country, with an account in the payout currency
        UserModel receiver = findReceiver(req)
                .orElseThrow(() -> new IllegalArgumentException(
                        "The recipient is not registered on ZentraPay. Pick their bank or mobile money wallet instead."));
        if (receiver.getUserId().equals(sender.getUserId())) {
            throw new IllegalArgumentException("You cannot send money to yourself");
        }
        if (!receiver.getCountryCode().equalsIgnoreCase(destinationCountryCode)) {
            throw new IllegalArgumentException("The recipient is not registered in " + destinationCountryCode.toUpperCase());
        }
        if (receiver.getStatus() != Datatypes.UserStatus.ACTIVE) {
            throw new IllegalArgumentException("The recipient's account cannot receive money at the moment");
        }

        FiatAccountModel senderAccount = accountOf(sender, sourceCurrency,
                "You currently don't have a " + sourceCurrency + " account. Please create one first");
        FiatAccountModel receiverAccount = accountOf(receiver, destinationCurrency,
                "The recipient has no " + destinationCurrency + " account to receive this payment");
        if (!"ACTIVE".equalsIgnoreCase(senderAccount.getStatus())) {
            throw new IllegalArgumentException("Your account is " + senderAccount.getStatus() + " at the moment");
        }

        // Amounts: the sender pays amount + fee, the receiver gets amount converted
        BigDecimal rate = exchangeRateService.rate(sourceCurrency, destinationCurrency);
        BigDecimal amount = scale(req.amount());
        BigDecimal fee = feeFor(amount);
        BigDecimal destinationAmount = scale(amount.multiply(rate));

        // One database transaction: debit (amount + fee), credit, transaction row, ledger lines, notifications.
        // The fee is simply retained (there is no revenue account yet).
        String reference = "ZR_" + NanoIdGenerator.randomNanoId("0123456789abcdefghijklmnopqrstuvwxyz", 16);
        TransactionModel draft = new TransactionModel();
        draft.setInternalReferenceId(reference);
        draft.setTransactionType(Datatypes.TransactionType.P2P_TRANSFER);
        draft.setAmount(amount.add(fee));
        draft.setSourceCurrencyCode(sourceCurrency);
        draft.setDestinationCurrencyCode(destinationCurrency);
        draft.setDestinationAmount(destinationAmount);
        draft.setPurpose(Optional.ofNullable(req.purpose()).filter(p -> !p.isBlank()).orElse("Cross-border remittance"));
        draft.setSenderId(sender.getUserId());
        draft.setSenderName(sender.getFirstName() + " " + sender.getLastName());
        draft.setSenderEmail(sender.getEmail());
        draft.setSenderPhoneNumber(sender.getPhoneNumber());
        draft.setReceiverId(receiver.getUserId());
        draft.setReceiverName(receiver.getFirstName() + " " + receiver.getLastName());
        draft.setReceiverEmail(receiver.getEmail());
        draft.setReceiverPhoneNumber(receiver.getPhoneNumber());
        draft.setDestinationIdentifier(receiverAccount.getZentag());
        TransactionModel saved = ledgerOperations.transferBetweenWallets(draft, senderAccount, receiverAccount);

        RemittanceModel remittance = new RemittanceModel();
        remittance.setSenderId(sender.getUserId());
        remittance.setReceiverId(receiver.getUserId());
        remittance.setTransactionId(saved.getTransactionId());
        remittance.setAmount(amount);
        remittance.setSourceCurrencyCode(sourceCurrency);
        remittance.setDestinationCurrencyCode(destinationCurrency);
        remittance.setExchangeRate(rate);
        remittance.setFee(fee);
        remittance.setStatus("SUCCESS");
        remittance.setChannel(Optional.ofNullable(req.channel()).filter(c -> !c.isBlank()).orElse("wallet"));
        remittance.setRecipientName(normalise(req.recipientName()));
        remittance.setRecipientPhoneNumber(normalise(req.recipientPhoneNumber()));
        remittance.setRecipientCountryCode(destinationCountryCode.toUpperCase());
        remittance.setReference(reference);
        remittancesRepository.save(remittance);

        log.info("========== REMIT DONE: {} ==========", reference);
        return toDTO(remittance, destinationAmount);
    }

    // ==================================================================
    // SEND to a bank account / mobile-money wallet abroad
    // ==================================================================

    private RemitResponseDTO sendToExternal(UserModel sender, RemitRequestDTO req, String recipientType,
                                            String destinationCountryCode, String sourceCurrency, String destinationCurrency) {
        boolean mobileMoney = "MOBILE_MONEY".equals(recipientType);
        String country = destinationCountryCode.toUpperCase();

        BigDecimal rate = exchangeRateService.rate(sourceCurrency, destinationCurrency);
        BigDecimal amount = scale(req.amount());
        BigDecimal fee = feeFor(amount);
        BigDecimal destinationAmount = scale(amount.multiply(rate));
        FiatAccountModel senderAccount = accountOf(sender, sourceCurrency,
                "You currently don't have a " + sourceCurrency + " account. Please create one first");
        if (!"ACTIVE".equalsIgnoreCase(senderAccount.getStatus())) {
            throw new IllegalArgumentException("Your account is " + senderAccount.getStatus() + " at the moment");
        }
        if (senderAccount.getBalance().compareTo(amount.add(fee)) < 0) {
            throw new IllegalArgumentException("Insufficient balance. Please top up your " + sourceCurrency + " account first");
        }

        // 1. Ask the providers who own the account - nothing is debited yet
        String accountNumber;
        String accountName;
        UUID destinationId;
        String destinationCode;
        if (mobileMoney) {
            accountNumber = normalise(req.recipientPhoneNumber());
            if (accountNumber.isEmpty()) {
                throw new IllegalArgumentException("Wallet phone number missing");
            }
            destinationId = req.mobileMoneyProviderId();
            destinationCode = req.mobileMoneyProviderCode();
            accountName = accountVerificationService.verifyMobileMoney(destinationId, destinationCode, accountNumber, country)
                    .map(AccountVerificationService.Verified::accountName)
                    .orElseGet(() -> normalise(req.recipientName()));
        } else {
            accountNumber = normalise(req.accountNumber());
            if (accountNumber.isEmpty()) {
                throw new IllegalArgumentException("Account number missing");
            }
            destinationId = req.bankId();
            destinationCode = req.bankCode();
            accountName = accountVerificationService.verifyBank(destinationId, destinationCode, accountNumber, country).accountName();
        }

        // 2. Find a provider that can take the recipient (still nothing debited)
        String purpose = Optional.ofNullable(req.purpose()).filter(p -> !p.isBlank()).orElse("Cross-border remittance");
        BankTransferServices.Payout payout = new BankTransferServices.Payout(recipientType, sender, true,
                destinationId, destinationCode, country, destinationCurrency, accountNumber, accountName,
                destinationAmount, purpose);
        BankTransferServices.Prepared prepared = bankTransferServices.prepare(payout);

        // 3. Debit the sender (amount + fee) and call the provider; a refusal refunds the sender
        String reference = "ZR_" + NanoIdGenerator.randomNanoId("0123456789abcdefghijklmnopqrstuvwxyz", 16);
        TransactionModel draft = new TransactionModel();
        draft.setInternalReferenceId(reference);
        draft.setTransactionType(mobileMoney ? Datatypes.TransactionType.CASH_OUT_MOMO : Datatypes.TransactionType.CASH_OUT_BANK);
        draft.setAmount(amount.add(fee));
        draft.setSourceCurrencyCode(sourceCurrency);
        draft.setDestinationCurrencyCode(destinationCurrency);
        draft.setDestinationAmount(destinationAmount);
        draft.setPurpose(purpose);
        draft.setSenderId(sender.getUserId());
        draft.setSenderName(sender.getFirstName() + " " + sender.getLastName());
        draft.setSenderEmail(sender.getEmail());
        draft.setSenderPhoneNumber(sender.getPhoneNumber());
        draft.setReceiverName(accountName);
        draft.setDestinationIdentifier(accountNumber);
        if (mobileMoney) {
            draft.setReceiverPhoneNumber(accountNumber);
        }
        draft.setGatewayId(prepared.gateway().getProviderId());
        TransactionModel debited = ledgerOperations.debitForPayout(draft, senderAccount);
        TransactionModel sent = bankTransferServices.send(debited, payout, prepared);

        RemittanceModel remittance = new RemittanceModel();
        remittance.setSenderId(sender.getUserId());
        remittance.setTransactionId(sent.getTransactionId());
        remittance.setAmount(amount);
        remittance.setSourceCurrencyCode(sourceCurrency);
        remittance.setDestinationCurrencyCode(destinationCurrency);
        remittance.setExchangeRate(rate);
        remittance.setFee(fee);
        remittance.setStatus(remittanceStatus(sent.getStatus()));
        remittance.setChannel(mobileMoney ? "mobile_money" : "bank");
        remittance.setRecipientName(accountName);
        remittance.setRecipientPhoneNumber(mobileMoney ? accountNumber : normalise(req.recipientPhoneNumber()));
        remittance.setRecipientCountryCode(country);
        remittance.setReference(reference);
        remittancesRepository.save(remittance);

        log.info("========== REMIT DONE: {} {} ==========", reference, sent.getStatus());
        return toDTO(remittance, destinationAmount);
    }

    // USER when a ZentraPay user was picked, else BANK / MOBILE_MONEY from the request
    private String recipientTypeOf(RemitRequestDTO req) {
        String type = normalise(req.recipientType()).toUpperCase();
        if (type.isEmpty()) {
            if (req.recipientUserId() != null) {
                return "USER";
            }
            if (req.mobileMoneyProviderId() != null || !normalise(req.mobileMoneyProviderCode()).isEmpty()) {
                return "MOBILE_MONEY";
            }
            if (req.bankId() != null || !normalise(req.bankCode()).isEmpty()) {
                return "BANK";
            }
            return "USER";
        }
        if (type.equals("MOMO")) {
            return "MOBILE_MONEY";
        }
        if (!List.of("USER", "BANK", "MOBILE_MONEY").contains(type)) {
            throw new IllegalArgumentException("Recipient type must be USER, BANK or MOBILE_MONEY");
        }
        return type;
    }

    // The remittance status mirrors the payout: money still on its way is PENDING
    private static String remittanceStatus(Datatypes.TransactionStatus status) {
        if (status == null) {
            return "PENDING";
        }
        return switch (status) {
            case SUCCESS -> "SUCCESS";
            case FAILED, REVERSED, EXPIRED -> "FAILED";
            default -> "PENDING";
        };
    }

    // ==================================================================
    // HISTORY and RATES
    // ==================================================================

    @Transactional(readOnly = true)
    public List<RemitResponseDTO> history(UUID senderId) {
        requireUser(senderId);
        return remittancesRepository.findBySenderIdOrderByCreatedAtDesc(senderId).stream()
                .map(r -> {
                    // A bank / mobile-money payout settles after the send (webhook), so read its status from the transaction
                    if ("PENDING".equals(r.getStatus())) {
                        transactionRepository.findById(r.getTransactionId())
                                .ifPresent(txn -> r.setStatus(remittanceStatus(txn.getStatus())));
                    }
                    return toDTO(r);
                })
                .toList();
    }

    // Lightweight FX preview for the picker (no sender context; the country rule is enforced on send)
    @Transactional(readOnly = true)
    public RemitQuoteResponseDTO rates(String sourceCurrencyCode, String destinationCurrencyCode, BigDecimal amount) {
        String source = normalise(sourceCurrencyCode);
        String destination = normalise(destinationCurrencyCode);
        BigDecimal safeAmount = amount == null || amount.signum() <= 0 ? BigDecimal.valueOf(100) : scale(amount);
        assertCurrencySupported(source);
        assertCurrencySupported(destination);

        BigDecimal rate = exchangeRateService.rate(source, destination);
        BigDecimal fee = feeFor(safeAmount);
        return new RemitQuoteResponseDTO(source, destination, "", rate, safeAmount,
                scale(safeAmount.multiply(rate)), fee, scale(safeAmount.add(fee)));
    }

    // ==================================================================
    // Helpers
    // ==================================================================

    private UserModel requireUser(UUID userId) {
        return userRepository.findById(userId).orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }

    // The receiver: by user id when the app searched a contact, else by phone number
    private Optional<UserModel> findReceiver(RemitRequestDTO req) {
        if (req.recipientUserId() != null) {
            return userRepository.findById(req.recipientUserId());
        }
        if (req.recipientPhoneNumber() != null && !req.recipientPhoneNumber().isBlank()) {
            return userRepository.findByPhoneNumber(req.recipientPhoneNumber().trim());
        }
        return Optional.empty();
    }

    private FiatAccountModel accountOf(UserModel user, String currency, String missingMessage) {
        FiatWalletModel wallet = fiatWalletRepository.getWalletByUserId(user.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("Wallet not found"));
        return fiatAccountRepository.findByWalletIdAndCurrencyCode(wallet.getWalletId(), currency)
                .orElseThrow(() -> new IllegalArgumentException(missingMessage));
    }

    private String normalise(String value) {
        return value == null ? "" : value.trim();
    }

    // Remittances are cross-border only: a recipient in the sender's own country is sent to the Pay flow
    private void assertCrossBorder(UserModel sender, String destinationCountryCode) {
        if (destinationCountryCode.isEmpty() || destinationCountryCode.equalsIgnoreCase(sender.getCountryCode())) {
            throw new IllegalArgumentException("The receiver is within the same country as you. Cross-border remittance "
                    + "is only for recipients in another country - please use the Pay section for domestic transfers.");
        }
    }

    // The destination country must be present AND active in the gateway directory
    private GatewayCountryModel requireActiveCountry(String countryCode) {
        return gatewayCountriesRepository.findFirstByCountryCode(countryCode.toUpperCase())
                .filter(GatewayCountryModel::isActive)
                .orElseThrow(() -> new IllegalArgumentException("We currently don't support remittances to "
                        + countryCode.toUpperCase() + ". Please choose another destination country"));
    }

    // Every currency involved must be present AND active in the gateway directory
    private void assertCurrencySupported(String currencyCode) {
        gatewayCurrenciesRepository.findById(currencyCode)
                .filter(GatewayCurrencyModel::isActive)
                .orElseThrow(() -> new IllegalArgumentException("We currently don't support "
                        + currencyCode.toUpperCase() + " transfers. Please choose another currency"));
    }

    private BigDecimal scale(BigDecimal value) {
        return value.setScale(2, RoundingMode.HALF_UP);
    }

    private BigDecimal feeFor(BigDecimal amount) {
        return amount.multiply(feePercent).divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
    }

    private static RemitResponseDTO toDTO(RemittanceModel r, BigDecimal destinationAmount) {
        return new RemitResponseDTO(r.getRemittanceId(), r.getTransactionId(), r.getReference(), r.getRecipientName(),
                r.getRecipientCountryCode(), r.getSourceCurrencyCode(), r.getDestinationCurrencyCode(), r.getAmount(),
                destinationAmount, r.getExchangeRate(), r.getFee(), r.getStatus(), r.getChannel(), r.getCreatedAt());
    }

    // History rows recompute the destination amount from the stored rate
    private static RemitResponseDTO toDTO(RemittanceModel r) {
        return toDTO(r, r.getAmount().multiply(r.getExchangeRate()).setScale(2, RoundingMode.HALF_UP));
    }
}
