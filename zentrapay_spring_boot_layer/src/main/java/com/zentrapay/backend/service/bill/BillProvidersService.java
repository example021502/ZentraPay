package com.zentrapay.backend.service.bill;

import com.zentrapay.backend.dto.bill.*;
import com.zentrapay.backend.dto.payment.GatewayTransferResult;
import com.zentrapay.backend.entity.*;
import com.zentrapay.backend.exception.PaymentGatewayException;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.repository.*;
import com.zentrapay.backend.security.AuthenticatedUser;
import com.zentrapay.backend.service.common.Datatypes;
import com.zentrapay.backend.service.gateway.FlutterwaveServices;
import com.zentrapay.backend.service.gateway.GatewayServices;
import com.zentrapay.backend.service.payment.LedgerOperations;
import com.zentrapay.backend.service.user.PinService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Bill providers (directory) and bill payments (electricity, TV, airtime ...).
 *
 * <p>Paying a bill follows the same money-safe steps as a bank payout: debit the wallet first
 * (transaction INITIATED), call the gateway, then PENDING / SUCCESS if it accepts, a refund if it
 * definitely refuses, and PENDING if the answer is unknown. Bills are paid through Flutterwave.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class BillProvidersService {

    private final BillProviderRepository billProviderRepository;
    private final BillPaymentRepository billPaymentRepository;
    private final UserRepository userRepository;
    private final FiatWalletRepository fiatWalletRepository;
    private final FiatAccountRepository fiatAccountRepository;
    private final TransactionRepository transactionRepository;
    private final LedgerOperations ledgerOperations;
    private final FlutterwaveServices flutterwaveServices;
    private final GatewayServices gatewayServices;
    private final PinService pinService;

    // ==================================================================
    // Directory
    // ==================================================================

    /**
     * Country-filtered, deduplicated bill-provider directory.
     * <p>
     * The client sends no country: the signed-in user's country decides the corridor (an explicit
     * {@code countryCode} query param still wins). Only active rows are returned, and because the
     * same biller can be offered by several gateways (one row per gateway), the result is collapsed
     * to ONE record per biller, preferring rows that carry a logo.
     */
    @Transactional(readOnly = true)
    public List<BillProviderDTO> listProviders(AuthenticatedUser user, String countryCode) {
        final String effectiveCountry = (countryCode == null || countryCode.isBlank())
                ? (user != null ? user.getCountryCode() : null)
                : countryCode;

        final List<BillProviderModel> providers =
                (effectiveCountry == null || effectiveCountry.isBlank())
                        ? billProviderRepository.findAll()
                        : billProviderRepository.findActiveByCountryCode(effectiveCountry.trim().toLowerCase());

        return dedupeByBiller(providers).stream()
                .map(BillProvidersService::toDTO)
                .toList();
    }

    // ==================================================================
    // Validate the customer reference (meter number, smartcard, phone ...)
    // ==================================================================

    public ValidateResponseDTO validate(ValidateRequestDTO request) {
        log.info("Validating bill customer for provider {}", request.providerId());
        BillProviderModel provider = requirePayableProvider(request.providerId());
        return flutterwaveServices.validateBillCustomer(provider.getBillerCode(), provider.getChannelCode(),
                request.customerReference().trim());
    }

    // ==================================================================
    // Pay
    // ==================================================================

    public PayResponseDTO pay(UUID userId, PayRequestDTO request) {
        // Debit the wallet, pay the bill through Flutterwave, refund if it definitely fails
        log.info("========== BILL PAYMENT START: user={} provider={} ==========", userId, request.providerId());
        UserModel user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        pinService.requireValid(user, request.pin());
        if (user.getStatus() != Datatypes.UserStatus.ACTIVE) {
            throw new IllegalArgumentException("Your account is " + user.getStatus() + " at the moment");
        }

        BillProviderModel provider = requirePayableProvider(request.providerId());
        GatewayModel flutterwave = gatewayServices.gatewayByName(Datatypes.PaymentGateway.FLUTTERWAVE);
        String currency = request.currencyCode().toUpperCase();
        BigDecimal amount = request.amount().setScale(2, RoundingMode.HALF_UP);
        String customer = request.customerReference().trim();

        FiatWalletModel wallet = fiatWalletRepository.getWalletByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("No wallet found"));
        FiatAccountModel account = fiatAccountRepository.findByWalletIdAndCurrencyCode(wallet.getWalletId(), currency)
                .orElseThrow(() -> new IllegalArgumentException("You do not have a " + currency + " account yet. Please create one first."));
        if (!"ACTIVE".equalsIgnoreCase(account.getStatus())) {
            throw new IllegalArgumentException("Your " + currency + " account is " + account.getStatus() + " at the moment");
        }
        if (account.getBalance().compareTo(amount) < 0) {
            throw new IllegalArgumentException("Insufficient balance. Please top up your " + currency + " account first");
        }

        // 1) Debit and record (INITIATED)
        TransactionModel draft = new TransactionModel();
        draft.setInternalReferenceId("BILL-" + UUID.randomUUID());
        draft.setTransactionType(Datatypes.TransactionType.BILL_PAYMENT);
        draft.setAmount(amount);
        draft.setSourceCurrencyCode(currency);
        draft.setDestinationCurrencyCode(currency);
        draft.setDestinationAmount(amount);
        draft.setPurpose("Bill payment: " + provider.getBillerName());
        draft.setSenderId(userId);
        draft.setSenderName(user.getFirstName() + " " + user.getLastName());
        draft.setSenderEmail(user.getEmail());
        draft.setSenderPhoneNumber(user.getPhoneNumber());
        draft.setReceiverName(provider.getBillerName());
        draft.setDestinationIdentifier(customer);
        draft.setGatewayId(flutterwave.getProviderId());
        TransactionModel txn = ledgerOperations.debitForPayout(draft, account);

        BillPaymentModel payment = new BillPaymentModel();
        payment.setUserId(userId);
        payment.setProviderId(provider.getProviderId());
        payment.setTransactionId(txn.getTransactionId());
        payment.setCustomerReference(customer);
        payment.setAmount(amount);
        payment.setCurrencyCode(currency);
        payment.setStatus("PENDING");
        payment = billPaymentRepository.save(payment);

        // 2) Call the gateway
        try {
            GatewayTransferResult result = flutterwaveServices.payBill(provider.getBillerCode(), provider.getChannelCode(),
                    provider.getCountryCode().toUpperCase(), customer, amount, LedgerOperations.gatewayReference(txn));
            txn = ledgerOperations.markSubmitted(txn.getTransactionId(), flutterwave.getProviderId(), result.settled());
            if (result.settled()) {
                payment.setStatus("SUCCESS");
                payment = billPaymentRepository.save(payment);
            }
        } catch (PaymentGatewayException e) {
            if (e.isOutcomeUnknown()) {
                // The bill may have been paid: keep the money held and let the reconciliation sort it out
                log.warn("Bill payment {} outcome UNKNOWN - kept PENDING: {}", txn.getInternalReferenceId(), e.getMessage());
                txn = ledgerOperations.markSubmitted(txn.getTransactionId(), flutterwave.getProviderId(), false);
            } else {
                log.warn("Bill payment {} refused: {}", txn.getInternalReferenceId(), e.getMessage());
                ledgerOperations.refund(txn.getTransactionId(), false, e.getMessage());
                payment.setStatus("FAILED");
                billPaymentRepository.save(payment);
                throw new PaymentGatewayException("The bill payment could not be completed and your money has been returned to your wallet.");
            }
        }

        log.info("========== BILL PAYMENT DONE: {} {} ==========", txn.getInternalReferenceId(), txn.getStatus());
        return new PayResponseDTO(new PaymentSummaryDTO(payment.getPaymentId(), txn.getStatus().name()), toTransactionDTO(txn, provider));
    }

    // ==================================================================
    // History
    // ==================================================================

    /** The user's latest bill payments; the status is read from the linked transaction so it is always current. */
    @Transactional(readOnly = true)
    public List<BillPaymentHistoryDTO> history(UUID userId) {
        List<BillPaymentModel> payments = billPaymentRepository.findTop50ByUserIdOrderByCreatedAtDesc(userId);
        Map<UUID, BillProviderModel> providers = billProviderRepository
                .findAllById(payments.stream().map(BillPaymentModel::getProviderId).collect(Collectors.toSet()))
                .stream().collect(Collectors.toMap(BillProviderModel::getProviderId, Function.identity()));
        Map<UUID, TransactionModel> transactions = transactionRepository
                .findAllById(payments.stream().map(BillPaymentModel::getTransactionId).collect(Collectors.toSet()))
                .stream().collect(Collectors.toMap(TransactionModel::getTransactionId, Function.identity()));

        return payments.stream().map(p -> {
            BillProviderModel provider = providers.get(p.getProviderId());
            TransactionModel txn = transactions.get(p.getTransactionId());
            return new BillPaymentHistoryDTO(p.getPaymentId(), provider == null ? null : provider.getBillerName(),
                    p.getCustomerReference(), p.getAmount(), p.getCurrencyCode(),
                    txn == null ? p.getStatus() : txn.getStatus().name(), p.getCreatedAt());
        }).toList();
    }

    // ==================================================================
    // Helpers
    // ==================================================================

    // An active provider that is wired to Flutterwave (has a gateway and an item code); seeded placeholder rows are not payable
    private BillProviderModel requirePayableProvider(UUID providerId) {
        BillProviderModel provider = billProviderRepository.findById(providerId)
                .orElseThrow(() -> new ResourceNotFoundException("Bill provider not found"));
        boolean payable = Boolean.TRUE.equals(provider.getActive())
                && "FLUTTERWAVE".equalsIgnoreCase(provider.getGateway())
                && provider.getChannelCode() != null && !provider.getChannelCode().isBlank();
        if (!payable) {
            throw new IllegalArgumentException("This bill provider cannot be paid right now");
        }
        return provider;
    }

    /**
     * Collapses multi-gateway duplicates down to a single record per biller.
     * Key is the biller code (falling back to the normalized biller name when a row has none);
     * when two rows describe the same biller, the one with a logo wins.
     */
    private static List<BillProviderModel> dedupeByBiller(List<BillProviderModel> providers) {
        final Map<String, BillProviderModel> unique = new LinkedHashMap<>();
        for (BillProviderModel p : providers) {
            if (p.getActive() != null && !p.getActive()) continue; // active-only
            final String code = p.getBillerCode();
            final String key = (code == null || code.isBlank()) ? normalize(p.getBillerName()) : normalize(code);
            final BillProviderModel existing = unique.get(key);
            if (existing == null || prefers(p, existing)) {
                unique.put(key, p);
            }
        }
        return new ArrayList<>(unique.values());
    }

    private static String normalize(String value) {
        return value == null ? "" : value.trim().toLowerCase();
    }

    /** True when [candidate] should replace [current] for the same biller. */
    private static boolean prefers(BillProviderModel candidate, BillProviderModel current) {
        return hasLogo(candidate) && !hasLogo(current);
    }

    private static boolean hasLogo(BillProviderModel p) {
        return p.getLogoUrl() != null && !p.getLogoUrl().isBlank();
    }

    private static BillProviderDTO toDTO(BillProviderModel p) {
        return new BillProviderDTO(p.getProviderId(), p.getBillerCode(), p.getBillerName(), p.getCategoryCode(),
                p.getCountryCode(), p.getLogoUrl(), p.getCreatedAt(), p.getUpdatedAt(), p.getChannelCode(),
                p.getIsCrossBorderAllowed(), p.getActive(), p.getFetchRequirement());
    }

    private static BillTransactionDTO toTransactionDTO(TransactionModel txn, BillProviderModel provider) {
        return new BillTransactionDTO(txn.getTransactionId(), txn.getTransactionType().name(), txn.getAmount(),
                txn.getSourceCurrencyCode(), txn.getStatus().name(), "FLUTTERWAVE", txn.getInternalReferenceId(),
                provider.getBillerName(), txn.getDestinationIdentifier(), txn.getPurpose(), txn.getCreatedAt());
    }
}
