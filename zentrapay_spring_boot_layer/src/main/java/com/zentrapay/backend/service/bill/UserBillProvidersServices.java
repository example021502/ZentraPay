// Updated UserBillProvidersServices aligned with the fixed LedgerOperations signatures and DTO fields
package com.zentrapay.backend.service.bill;

import com.zentrapay.backend.dto.bill.*;
import com.zentrapay.backend.dto.gateway.*;
import com.zentrapay.backend.entity.*;
import com.zentrapay.backend.exception.PaymentGatewayException;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.repository.*;
import com.zentrapay.backend.service.AccountsLimit.AccountsLimitServices;
import com.zentrapay.backend.service.CountriesServices;
import com.zentrapay.backend.service.common.Datatypes;
import com.zentrapay.backend.service.common.Utils;
import com.zentrapay.backend.service.gateway.FlutterwaveServices;
import com.zentrapay.backend.service.gateway.OnafriqServices;
import com.zentrapay.backend.service.gateway.PaystackServices;
import com.zentrapay.backend.service.notification.NotificationsService;
import com.zentrapay.backend.service.payment.LedgerOperations;
import com.zentrapay.backend.service.transaction.TransactionsServices;
import com.zentrapay.backend.service.user.PinService;
import com.zentrapay.backend.service.user.UsersService;
import com.zentrapay.backend.service.DigitalAccounts.AccountsServices;

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
 * Bill providers (directory) and bill payments (electricity, TV, airtime, etc.).
 *
 * <p>Paying a bill follows a money-safe lifecycle: validate inputs and user/account eligibility,
 * create a draft transaction, debit the wallet, call the bill payment gateway,
 * settle into provider float on success, refund from pending clearing on a definite refusal,
 * or keep PENDING when the upstream outcome is unknown pending reconciliation.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class UserBillProvidersServices {

    private final CountriesServices countriesServices;
    private final AccountsLimitServices accountsLimitServices;
    private final BillProviderRepository billProviders;
    private final BillProviderRepository billProviderRepository;
    private final BillPaymentRepository billPaymentRepository;
    private final TransactionRepository transactionRepository;
    private final AccountsServices accountsServices;
    private final UserBillProvidersRepository userBillProvidersRepository;
    private final BillPaymentsServices billPaymentsServices;

    private final FlutterwaveServices flutterwaveServices;
    private final OnafriqServices onafriqServices;
    private final PaystackServices paystackServices;
    private final LedgerOperations ledgerOperations;
    private final TransactionsServices transactionsServices;
    private final PinService pinService;
    private final UsersService usersService;

    private final NotificationsService notificationsService;

    // ==================================================================
    // Directory
    // ==================================================================

    @Transactional(readOnly = true)
    public List<BillProviderDTO> listProviders(String countryCode) {
        // Ensure the requested country is supported by ZentraPay before querying billers
        countriesServices.requireSupportCountry(countryCode);
        List<BillProviderModel> providers = dedupeByBiller(
                billProviders.getProvidersByCountryCode(countryCode.toUpperCase())
        );
        return providers.stream()
                .map(UserBillProvidersServices::toDTO)
                .toList();
    }

    // ==================================================================
    // Validate the customer reference (meter number, smartcard, phone ...)
    // ==================================================================

    @Transactional(readOnly = true)
    public ValidateResponseDTO validate(ValidateRequestDTO request) {
        // Trim customer identifier before querying biller validation endpoints
        String customerRef = request.customerReference().trim();
        log.info("==== Validating bill customer for provider {} ====", request.providerId());

        BillProviderModel provider = requirePayableProvider(request.providerId());

        // Primary bill customer validation via Flutterwave
        FlutterwaveValidateBillAccountResponseDTO flwResult = flutterwaveServices.validateBillAccount(
                provider.getCode(),
                provider.getChannelCode(),
                customerRef
        );
        if (flwResult != null && flwResult.success() && flwResult.data() != null) {
            return new ValidateResponseDTO(true, flwResult.data().name());
        }

        // Secondary fallback lookup via Paystack if supported for the provider/channel
        PaystackValidateBillAccountResponseDTO pskResult = paystackServices.validateBillAccount(
                provider.getCode(),
                provider.getChannelCode(),
                customerRef
        );
        if (pskResult != null && pskResult.success() && pskResult.data() != null) {
            return new ValidateResponseDTO(true, pskResult.data().accountName());
        }

        throw new IllegalArgumentException("Account validation failed. Please verify your customer reference and try again.");
    }

    // ==================================================================
    // Pay
    // ==================================================================

    @Transactional
    public PayResponseDTO pay(UUID userId, PayRequestDTO request) throws IllegalAccessException {
        log.info("========== BILL PAYMENT START for user {} ==========", userId);

        // 1.) Check idempotency and replay prior payment if already initiated
        if (checkIdempotencyExists(request.idempotencyKey())) {
            return ReplayBillPayment(request, userId);
        }

        // Validate user status, PIN, sender eligibility, KYC, and transaction limits
        UserModel user = usersService.getUser(userId);
        usersService.requireActiveUser(user);
        pinService.requireValid(user, request.pin());
        usersService.requireEligibleSender(user);
        usersService.checkKycStatus(user);
        accountsLimitServices.checkAccountLimit(user.getKycTier(), request.amount(), request.currencyCode());

        String sourceCurrencyCode = request.currencyCode().trim().toUpperCase();
        BigDecimal amount = request.amount().setScale(2, RoundingMode.HALF_UP);
        String customer = request.customerReference().trim();

        // Verify user-to-provider linkage and matching currency
        UserBillProviderModel userBillProvider = userBillProvidersRepository
                .getAccountByUserIdAndProviderId(userId, request.providerId())
                .orElseThrow(() -> new RuntimeException(
                        "User and Bill provider connection can not be resolved. Please, re connect with the bill providers and retry."
                ));

        if (!sourceCurrencyCode.equalsIgnoreCase(userBillProvider.getCurrencyCode())) {
            throw new RuntimeException(
                    "Invalid currency. Please use your " + userBillProvider.getCurrencyCode() + " account for this operation."
            );
        }

        // Confirm country support, provider activity, and cross-border rules
        BillProviderModel provider = requirePayableProvider(request.providerId());
        countriesServices.requireSupportCountry(provider.getCountryCode());

        if (!Boolean.TRUE.equals(provider.getActive())) {
            throw new RuntimeException("The provider is currently not active. Try again later.");
        }
        if (!user.getCountryCode().equalsIgnoreCase(provider.getCountryCode())
                && !Boolean.TRUE.equals(provider.getIsCrossBorderAllowed())) {
            throw new RuntimeException("Cross border transfers are not supported at the moment.");
        }

        // 2.) Debit sender account, create draft transaction & bill payment records, and record debit ledger entry
        AccountsModel senderAccount = accountsServices.getAccount(userId, sourceCurrencyCode, null);
        BigDecimal runningBalance = accountsServices.debit(amount, sourceCurrencyCode, senderAccount.getId());

        // Save initial draft transaction record
        TransactionModel draft = transactionsServices.addNew(
                request.idempotencyKey(),
                amount,
                sourceCurrencyCode,
                userBillProvider.getCurrencyCode(),
                amount,
                "Bill Payment for " + userBillProvider.getLabel() + "(" + userBillProvider.getCustomerName() + ")",
                userId,
                user.getFirstName() + " " + user.getLastName(),
                user.getEmail(),
                user.getPhoneNumber(),
                customer,
                provider.getName(),
                provider.getId()
        );

        // Post double-entry debit leg for the sender account
        ledgerOperations.debit(
                draft.getId(),
                draft.getEntryId(),
                accountsServices.getZentag(userId, sourceCurrencyCode),
                amount,
                runningBalance,
                sourceCurrencyCode,
                "Debited " + sourceCurrencyCode + " " + amount + " from your "
                        + senderAccount.getLabel()
                        + " account for your " + provider.getName()
        );

        // Save bill payment tracking record linked to the draft transaction
        BillPaymentModel billPayment = billPaymentsServices.addNew(
                userId,
                userBillProvider.getProviderId(),
                request.idempotencyKey(),
                draft.getId(),
                request.customerReference(),
                request.amount(),
                request.currencyCode()
        );

        // Notify sender of the debit initiation
        notificationsService.pushNotification(
                userId,
                "Bill payment",
                "Paying " + sourceCurrencyCode + " " + amount + " to " + provider.getName()
                        + " cover your " + userBillProvider.getLabel() + " bill.",
                Datatypes.NotificationTypes.DEBIT,
                request.customerReference()
        );

        // 3.) Execute bill payment via Flutterwave (with optional Onafriq fallback when Flutterwave does not complete)
        Datatypes.Gateway activeGateway = Datatypes.Gateway.FLUTTERWAVE;
        try {
            String gatewayRef = Utils.getRandomId("zp_");
            FlutterwaveBillPaymentResponseDTO flwResult = flutterwaveServices.payBill(
                    provider.getCode(),
                    provider.getChannelCode(),
                    provider.getCountryCode().toUpperCase(),
                    customer,
                    amount,
                    gatewayRef
            );

            boolean flwAccepted = flwResult != null
                    && "success".equalsIgnoreCase(flwResult.status())
                    && flwResult.data() != null;

            if (!flwAccepted) {
                // Attempt secondary gateway via Onafriq when Flutterwave does not accept the payment
                activeGateway = Datatypes.Gateway.ONAFRIQ;
                OnAfriqBillPaymentResponseDTO onafriqResult = onafriqServices.payBill(
                        gatewayRef,
                        amount,
                        sourceCurrencyCode,
                        provider.getCountryCode().toUpperCase(),
                        provider.getCode(),
                        customer,
                        user.getPhoneNumber()
                );

                if (onafriqResult == null || !"SUCCESSFUL".equalsIgnoreCase(onafriqResult.status()) || onafriqResult.data() == null) {
                    throw new PaymentGatewayException("Bill payment failed on both gateways.");
                }

                processResponse(activeGateway, onafriqResult, billPayment, draft, senderAccount.getId());
            } else {
                processResponse(activeGateway, flwResult, billPayment, draft, senderAccount.getId());
            }

        } catch (PaymentGatewayException e) {
            if (e.isOutcomeUnknown()) {
                // Keep funds held in pending clearing and mark submitted as unsettled for reconciliation
                log.warn("Bill payment {} outcome UNKNOWN - kept PENDING: {}", draft.getInternalReferenceId(), e.getMessage());
                draft = ledgerOperations.markSubmitted(draft.getId(), provider.getId(), false);
                billPayment.setStatus(Datatypes.TransactionStatus.PENDING);
                billPaymentRepository.save(billPayment);
            } else {
                // Definite refusal: refund debit from clearing back to sender account and mark payment FAILED
                log.warn("Bill payment {} refused: {}", draft.getInternalReferenceId(), e.getMessage());
                ledgerOperations.refundFailedBill(
                        draft.getId(),
                        draft.getEntryId(),
                        resolvePendingBillsClearingAccountId(sourceCurrencyCode),
                        senderAccount.getId(),
                        amount,
                        sourceCurrencyCode
                );
                billPayment.setStatus(Datatypes.TransactionStatus.FAILED);
                draft.setStatus(Datatypes.TransactionStatus.FAILED);
                billPaymentRepository.save(billPayment);
                transactionsServices.save(draft);
                throw new PaymentGatewayException(
                        "The bill payment could not be completed and your money has been returned to your wallet."
                );
            }
        }

        log.info("========== BILL PAYMENT DONE: {} {} ==========", draft.getInternalReferenceId(), draft.getStatus());
        return new PayResponseDTO(
                new PaymentSummaryDTO(billPayment.getId(), draft.getStatus().name()),
                toTransactionDTO(draft, provider, activeGateway)
        );
    }

    // Overloaded response processor for Flutterwave bill payment responses
    public void processResponse(
            Datatypes.Gateway gateway,
            FlutterwaveBillPaymentResponseDTO response,
            BillPaymentModel payment,
            TransactionModel transaction,
            UUID userWalletAccountId
    ) {
        String topStatus = response != null ? response.status() : null;
        var data = response != null ? response.data() : null;
        String currencyCode = transaction.getSourceCurrencyCode();

        if ("success".equalsIgnoreCase(topStatus) && data != null) {
            // Scenario A: Settle from pending bills clearing into provider float and mark completed
            ledgerOperations.settleBillSuccess(
                    transaction.getId(),
                    transaction.getEntryId(),
                    resolvePendingBillsClearingAccountId(currencyCode),
                    resolveProviderFloatAccountId(gateway, currencyCode),
                    transaction.getAmount(),
                    currencyCode
            );
            payment.setStatus(Datatypes.TransactionStatus.SUCCESS);
            transaction.setStatus(Datatypes.TransactionStatus.SUCCESS);
            payment.setToken(data.rechargeToken());
        } else if ("error".equalsIgnoreCase(topStatus) || "failed".equalsIgnoreCase(topStatus)) {
            // Scenario B: Refund from pending bills clearing back to user wallet account and mark failed
            ledgerOperations.refundFailedBill(
                    transaction.getId(),
                    transaction.getEntryId(),
                    resolvePendingBillsClearingAccountId(currencyCode),
                    userWalletAccountId,
                    transaction.getAmount(),
                    currencyCode
            );
            payment.setStatus(Datatypes.TransactionStatus.FAILED);
            transaction.setStatus(Datatypes.TransactionStatus.FAILED);
        } else {
            // Scenario C: Still processing -> keep PENDING for webhook and scheduled poller
            payment.setStatus(Datatypes.TransactionStatus.PENDING);
            transaction.setStatus(Datatypes.TransactionStatus.PENDING);
        }

        billPaymentRepository.save(payment);
        transactionsServices.save(transaction);
    }

    // Overloaded response processor for Onafriq bill payment responses
    public void processResponse(
            Datatypes.Gateway gateway,
            OnAfriqBillPaymentResponseDTO response,
            BillPaymentModel payment,
            TransactionModel transaction,
            UUID userWalletAccountId
    ) {
        String status = (response != null && response.data() != null) ? response.status() : null;
        String currencyCode = transaction.getSourceCurrencyCode();

        if ("SUCCESSFUL".equalsIgnoreCase(status) || "COMPLETED".equalsIgnoreCase(status)) {
            // Scenario A: Settle from pending bills clearing into provider float
            ledgerOperations.settleBillSuccess(
                    transaction.getId(),
                    transaction.getEntryId(),
                    resolvePendingBillsClearingAccountId(currencyCode),
                    resolveProviderFloatAccountId(gateway, currencyCode),
                    transaction.getAmount(),
                    currencyCode
            );
            payment.setStatus(Datatypes.TransactionStatus.SUCCESS);
            transaction.setStatus(Datatypes.TransactionStatus.SUCCESS);
            payment.setToken(response.data().token());
        } else if ("FAILED".equalsIgnoreCase(status) || "REJECTED".equalsIgnoreCase(status)) {
            // Scenario B: Refund from pending bills clearing back to user wallet account
            ledgerOperations.refundFailedBill(
                    transaction.getId(),
                    transaction.getEntryId(),
                    resolvePendingBillsClearingAccountId(currencyCode),
                    userWalletAccountId,
                    transaction.getAmount(),
                    currencyCode
            );
            payment.setStatus(Datatypes.TransactionStatus.FAILED);
            transaction.setStatus(Datatypes.TransactionStatus.FAILED);
        } else {
            // Scenario C: Async pending -> wait for webhook or poller
            payment.setStatus(Datatypes.TransactionStatus.PENDING);
            transaction.setStatus(Datatypes.TransactionStatus.PENDING);
        }

        billPaymentRepository.save(payment);
        transactionsServices.save(transaction);
    }

    // CHECK IDEMPOTENCY KEY
    public boolean checkIdempotencyExists(String key) {
        return billPaymentRepository.existsByIdempotencyKey(key);
    }

    // REPLAY PREVIOUS OPERATION
    // Replay existing payment state for duplicate idempotency keys without re-running ledger mutations
    @Transactional(readOnly = true)
    public PayResponseDTO replayBillPayment(PayRequestDTO req, UUID userId) {
        if (req == null || req.idempotencyKey() == null || req.idempotencyKey().isBlank()) {
            throw new IllegalArgumentException("Idempotency key is required for replay");
        }
        if (userId == null) {
            throw new IllegalArgumentException("User ID is required for replay");
        }

        // Look up the existing payment record associated with this idempotency key
        TransactionModel existingTx = transactionsServices
                .findByIdempotencyKey(req.idempotencyKey().trim())
                .orElseThrow(() -> new IllegalStateException(
                        "No existing bill payment found for idempotency key: " + req.getIdempotencyKey()
                ));

        // Ensure the caller owns the original transaction
        if (!userId.equals(existingTx.getUserId())) {
            throw new SecurityException("Idempotency key belongs to a different user");
        }

        // Guard against reusing the same idempotency key with a conflicting amount or currency
        if (req.getAmount() != null && existingTx.getAmount() != null
                && existingTx.getAmount().compareTo(req.getAmount()) != 0) {
            throw new IllegalStateException("Idempotency key reused with a different amount");
        }
        if (req.getCurrencyCode() != null && existingTx.getCurrencyCode() != null
                && !existingTx.getCurrencyCode().equalsIgnoreCase(req.getCurrencyCode().trim())) {
            throw new IllegalStateException("Idempotency key reused with a different currency");
        }

        // Map the persisted transaction state back into PayResponseDTO without touching accounts or ledger_entries
        return PayResponseDTO.builder()
                .transactionId(existingTx.getId())
                .idempotencyKey(existingTx.getIdempotencyKey())
                .gateway(existingTx.getGateway())
                .currencyCode(existingTx.getCurrencyCode())
                .amount(existingTx.getAmount())
                .status(existingTx.getStatus())
                .providerReference(existingTx.getProviderReference())
                .message("Replayed existing payment state: " + existingTx.getStatus())
                .build();
    }
    // ==================================================================
    // History
    // ==================================================================

    @Transactional(readOnly = true)
    public List<BillPaymentHistoryDTO> history(UUID userId) {
        // Fetch up to 50 most recent bill payments for the user
        List<BillPaymentModel> payments = billPaymentRepository.findTop50ByUserIdOrderByCreatedAtDesc(userId);
        if (payments.isEmpty()) {
            return List.of();
        }

        // Batch-load related providers and transactions to avoid N+1 queries
        Map<UUID, BillProviderModel> providers = billProviderRepository
                .findAllById(payments.stream().map(BillPaymentModel::getProviderId).collect(Collectors.toSet()))
                .stream()
                .collect(Collectors.toMap(BillProviderModel::getId, Function.identity()));

        Map<UUID, TransactionModel> transactions = transactionRepository
                .findAllById(payments.stream().map(BillPaymentModel::getTransactionId).collect(Collectors.toSet()))
                .stream()
                .collect(Collectors.toMap(TransactionModel::getId, Function.identity()));

        return payments.stream().map(p -> {
            BillProviderModel provider = providers.get(p.getProviderId());
            TransactionModel txn = transactions.get(p.getTransactionId());
            return new BillPaymentHistoryDTO(
                    p.getId(),
                    provider == null ? null : provider.getName(),
                    p.getCustomerReference(),
                    p.getAmount(),
                    p.getCurrencyCode(),
                    txn == null ? p.getStatus() : txn.getStatus(),
                    p.getCreatedAt()
            );
        }).toList();
    }

    // ==================================================================
    // Helpers
    // ==================================================================

    // Resolve currency-specific pending bills clearing ledger account ID
    private UUID resolvePendingBillsClearingAccountId(String currencyCode) {
        return accountsServices.getOrCreateSystemClearingAccount(Datatypes.AccountTypes.CLEARING, currencyCode);
    }

    // Resolve gateway- and currency-specific float ledger account ID
    private UUID resolveProviderFloatAccountId(Datatypes.Gateway gateway, String currencyCode) {
        return accountsServices.getOrCreateSystemFloatAccount(gateway, currencyCode);
    }

    private BillProviderModel requirePayableProvider(UUID providerId) {
        // Ensure the bill provider exists, is active, is routed via Flutterwave, and has a channel/item code
        BillProviderModel provider = billProviderRepository.findById(providerId)
                .orElseThrow(() -> new ResourceNotFoundException("Bill provider not found"));
        boolean payable = Boolean.TRUE.equals(provider.getActive())
                && Datatypes.Gateway.FLUTTERWAVE.equals(provider.getGateway())
                && provider.getChannelCode() != null && !provider.getChannelCode().isBlank()
                && provider.getCode() != null && !provider.getCode().isBlank();
        if (!payable) {
            throw new IllegalArgumentException("This bill provider cannot be paid right now");
        }
        return provider;
    }

    private static List<BillProviderModel> dedupeByBiller(List<BillProviderModel> providers) {
        final Map<String, BillProviderModel> unique = new LinkedHashMap<>();
        for (BillProviderModel p : providers) {
            if (p.getActive() != null && !p.getActive()) {
                continue;
            }
            final String code = p.getCode();
            final String key = (code == null || code.isBlank()) ? normalize(p.getName()) : normalize(code);
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

    private static boolean prefers(BillProviderModel candidate, BillProviderModel current) {
        return hasLogo(candidate) && !hasLogo(current);
    }

    private static boolean hasLogo(BillProviderModel p) {
        return p.getLogoUrl() != null && !p.getLogoUrl().isBlank();
    }

    private static BillProviderDTO toDTO(BillProviderModel p) {
        return new BillProviderDTO(
                p.getId(),
                p.getCode(),
                p.getName(),
                p.getCategoryCode(),
                p.getCountryCode(),
                p.getLogoUrl(),
                p.getCreatedAt(),
                p.getUpdatedAt(),
                p.getChannelCode(),
                p.getIsCrossBorderAllowed(),
                p.getActive(),
                p.getFetchRequirement()
        );
    }

    private static BillTransactionDTO toTransactionDTO(TransactionModel txn, BillProviderModel provider, Datatypes.Gateway gateway) {
        return new BillTransactionDTO(
                txn.getId(),
                txn.getTransactionType().name(),
                txn.getAmount(),
                txn.getSourceCurrencyCode(),
                txn.getStatus().name(),
                gateway,
                txn.getInternalReferenceId(),
                provider.getName(),
                txn.getDestinationIdentifier(),
                txn.getPurpose(),
                txn.getCreatedAt()
        );
    }
}