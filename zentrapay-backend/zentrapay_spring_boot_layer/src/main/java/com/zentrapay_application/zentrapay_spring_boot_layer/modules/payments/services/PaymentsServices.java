package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.services;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.DisbursementRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.PaymentsResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.WalletToWalletRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.gateway.PaymentGatewayFactory;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.model.PaymentsUsersModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.model.UsersWalletsModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.repository.UserWalletsRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.model.TransactionModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.repository.TransactionRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * Core service for processing payments — both internal wallet-to-wallet
 * transfers and external disbursements via Paystack.
 * <p>
 * Mirrors the logic from the Node.js Express layer's {@code paymentsRoutes.js},
 * adapted for Spring Boot with proper transactional guarantees.
 */
@Service
@Transactional
@RequiredArgsConstructor
public class PaymentsServices {

    private static final Logger log = LoggerFactory.getLogger(PaymentsServices.class);

    private final UserWalletsRepository userWalletsRepository;
    private final TransactionRepository transactionRepository;
    private final PaymentGatewayFactory paymentGatewayFactory;
    private final PasswordEncoder passwordEncoder;
    @Value("${app.pin.pepper}")
    private String pinPepper;

    // ========================================================================
    // TRANSACTIONAL GUARANTEE
    // ========================================================================
    // All payment operations in this service are wrapped in @Transactional.
    // This means that wallet balance updates (debit/credit) and transaction
    // history records are saved atomically in ONE database transaction.
    //
    // If any step fails, Spring automatically rolls back:
    // ✓ Wallet debits are reversed
    // ✓ Wallet credits are reversed
    // ✓ Transaction history records are NOT saved
    //
    // This guarantees that transaction history ALWAYS matches actual balances.
    // ========================================================================

    // ========================================================================
    // INTERNAL WALLET-TO-WALLET PAYMENT
    // Mirrors Node.js: POST /api/payments/internal
    // ========================================================================

    /**
     * Processes an internal wallet-to-wallet transfer between two ZentraPay app users.
     * <p>
     * This entire method runs within a single @Transactional boundary, ensuring:
     * <ol>
     *   <li>Sender and receiver wallets are validated</li>
     *   <li>Sender is debited AND receiver is credited atomically</li>
     *   <li>Transaction history record is saved in the same transaction</li>
     * </ol>
     * <p>
     * If any step fails, ALL changes are rolled back automatically.
     * <p>
     * Mirrors Node.js route: {@code POST /api/payments/internal}
     *
     * @param request The validated wallet-to-wallet request
     * @return Standardized payment response
     */
    public PaymentsResponseDTO makePaymentToAppUser(@Valid WalletToWalletRequestDTO request) {
        log.info("[PAYMENT_SERVICE] Internal transfer: sender={}, amount={} {}",
                request.userId(), request.paymentDetails().amount(), request.paymentDetails().currencyCode());

        // Step 1: Validate sender
        PaymentsUsersModel sender = userWalletsRepository.existsByUserIdOrPhoneNumber(request.userId(), null, null);
        if (sender == null) {
            log.error("[PAYMENT_SERVICE] Sender not found: userId={}", request.userId());
            throw new RuntimeException("Sender not found");
        }

        // Step 2: Find receiver by phoneNumber or zentag
        String phoneNumber = request.recipient().phoneNumber();
        String zentag = request.recipient().zentag();
        if ((phoneNumber == null || phoneNumber.isBlank()) && (zentag == null || zentag.isBlank())) {
            throw new RuntimeException("Receiver identifier missing: provide phoneNumber or Zentag");
        }

        PaymentsUsersModel receiver = userWalletsRepository.existsByUserIdOrPhoneNumber(null, phoneNumber, zentag);
        if (receiver == null) {
            log.error("[PAYMENT_SERVICE] Receiver not found: phone={}, zentag={}", phoneNumber, zentag);
            throw new RuntimeException("Receiver not found");
        }

        // Step 3: Prevent self-transfer
        if (sender.getUserId().equals(receiver.getUserId())) {
            throw new RuntimeException("Cannot transfer money to your own wallet");
        }

        String currencyCode = request.paymentDetails().currencyCode();

        // Step 4: Validate wallets
        UsersWalletsModel senderWallet = userWalletsRepository.getWalletByUserIdAndCurrencyCode(sender.getUserId(), currencyCode);
        if (senderWallet == null) {
            throw new RuntimeException("Sender wallet not found for currency: " + currencyCode);
        }

        UsersWalletsModel receiverWallet = userWalletsRepository.getWalletByUserIdAndCurrencyCode(receiver.getUserId(), currencyCode);
        if (receiverWallet == null) {
            throw new RuntimeException("Receiver wallet not found for currency: " + currencyCode);
        }

        // Step 5: Check balance
        if (senderWallet.getBalance().compareTo(request.paymentDetails().amount()) < 0) {
            throw new RuntimeException("Insufficient balance");
        }

        // Step 6: Execute transfer (debit sender, credit receiver)
        int debitResult = userWalletsRepository.debit(request.userId(), currencyCode, request.paymentDetails().amount());
        if (debitResult == 0) {
            throw new RuntimeException("Failed to debit sender wallet");
        }

        int creditResult = userWalletsRepository.credit(receiver.getUserId(), currencyCode, request.paymentDetails().amount());
        if (creditResult == 0) {
            // Attempt rollback by crediting back the sender
            userWalletsRepository.credit(request.userId(), currencyCode, request.paymentDetails().amount());
            throw new RuntimeException("Failed to credit receiver wallet — transfer reversed");
        }

        // Step 7: Generate transaction reference
        String transactionReference = UUID.randomUUID().toString();

        // Step 8: Build transaction metadata
        String gatewayName = "ZentraPayInternal";
        BigDecimal fee = BigDecimal.ZERO;
        BigDecimal totalCharged = request.paymentDetails().amount().add(fee);
        String status = "SUCCESSFUL";
        String paymentChannel = "WALLET_TRANSFER";
        Instant now = Instant.now();

        saveTransaction(
                sender.getUserId(),
                receiver.getUserId(),
                senderWallet.getWalletId(),
                receiverWallet.getWalletId(),
                gatewayName,
                request.paymentDetails().amount(),
                currencyCode,
                fee,
                status,
                transactionReference,
                paymentChannel
        );

        log.info("[PAYMENT_SERVICE] Internal transfer successful: ref={}, sender={}, receiver={}, amount={} {}",
                transactionReference, sender.getUserId(), receiver.getUserId(),
                request.paymentDetails().amount(), currencyCode);

        return new PaymentsResponseDTO(
                transactionReference,
                gatewayName,
                request.paymentDetails().amount(),
                currencyCode,
                fee,
                totalCharged,
                status,
                paymentChannel,
                null,
                null,
                now
        );
    }

    // ========================================================================
    // EXTERNAL DISBURSEMENT (via Gateway Factory)
    // Mirrors Node.js: POST /api/payments/disbursement
    // Routes through Paystack (primary), Onafriq (international), or Flutterwave (failover)
    // ========================================================================

    /**
     * Processes an outbound disbursement to an external recipient (bank, mobile money, etc.).
     * <p>
     * This entire method runs within a single @Transactional boundary, ensuring:
     * <ol>
     *   <li>Sender wallet is debited</li>
     *   <li>Gateway processes the disbursement (with automatic failover)</li>
     *   <li>Transaction history record is saved atomically</li>
     * </ol>
     * <p>
     * If the gateway fails, the sender is re-credited BEFORE the transaction
     * is saved, maintaining consistency. If the save fails, everything rolls back.
     * <p>
     * Mirrors Node.js route: {@code POST /api/payments/disbursement}
     *
     * @param request The validated disbursement request
     * @return Standardized payment response
     */
    public PaymentsResponseDTO makeDisbursement(@Valid DisbursementRequestDTO request) {
        String currencyCode = request.paymentDetails().sourceCurrency();
        log.info("[PAYMENT_SERVICE] Disbursement: sender={}, amount={} {}, reference={}",
                request.userId(), request.paymentDetails().amount(), currencyCode,
                request.paymentDetails().reference());

        // Step 1: Validate sender
        PaymentsUsersModel sender = userWalletsRepository.existsByUserIdAndEmail(request.userId(), request.email());
        if (sender == null) {
            log.error("[PAYMENT_SERVICE] Sender not found: userId={} and email={}", request.userId(), request.email());
            throw new RuntimeException("Sender not found");
        }

        // Step 2: Validate sender wallet
        UsersWalletsModel senderWallet = userWalletsRepository.getWalletByUserIdAndCurrencyCode(sender.getUserId(), currencyCode);
        if (senderWallet == null) {
            throw new RuntimeException("Sender wallet not found for currency: " + currencyCode);
        }

        // Step 3: Check sufficient balance
        if (senderWallet.getBalance().compareTo(request.paymentDetails().amount()) < 0) {
            throw new RuntimeException("Insufficient balance");
        }

        final String rawPinWithPepper = request.pin() + pinPepper;

        // Verify provided pin to authenticate the transaction
        boolean isAuthenticated = passwordEncoder.matches(rawPinWithPepper, sender.getPin());
        if (!isAuthenticated) {
            throw new RuntimeException("Wrong PIN!");
        }
        
        // Step 4: Debit sender wallet
        int debitResult = userWalletsRepository.debit(request.userId(), currencyCode, request.paymentDetails().amount());
        if (debitResult == 0) {
            throw new RuntimeException("Failed to debit sender wallet");
        }

        // Step 5: Process via the appropriate gateway (Paystack, Onafriq, or Flutterwave)
        // The gateway factory handles failover automatically
        PaymentsResponseDTO gatewayResponse;
        try {
            gatewayResponse = paymentGatewayFactory.processDisbursement(request);
        } catch (Exception e) {
            // Re-credit sender if ALL gateways fail
            userWalletsRepository.credit(request.userId(), currencyCode, request.paymentDetails().amount());
            log.error("[PAYMENT_SERVICE] All gateways failed, re-crediting sender: userId={}, error={}",
                    request.userId(), e.getMessage());
            throw new RuntimeException("Disbursement failed: " + e.getMessage());
        }

        // Step 6: Persist transaction record
        // This happens within the same @Transactional boundary, ensuring wallet and transaction are atomic
        String paymentChannel = request.paymentDetails().destinationType() != null
                ? request.paymentDetails().destinationType()
                : "MOBILE_MONEY";

        String effectiveReference = gatewayResponse.transactionReference() != null
                ? gatewayResponse.transactionReference()
                : "DISB-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        // Use the actual gateway name that processed the transaction for accurate history
        String actualGatewayName = gatewayResponse.gatewayName() != null
                ? gatewayResponse.gatewayName()
                : paymentGatewayFactory.getPrimaryGatewayName(request.paymentDetails().isInternational(), currencyCode);

        saveTransaction(
                sender.getUserId(),
                null,
                senderWallet.getWalletId(),
                null,
                actualGatewayName,
                request.paymentDetails().amount(),
                currencyCode,
                BigDecimal.ZERO,
                gatewayResponse.status(),
                effectiveReference,
                paymentChannel
        );

        log.info("[PAYMENT_SERVICE] Disbursement processed: ref={}, status={}, gateway={}",
                effectiveReference, gatewayResponse.status(), actualGatewayName);

        // Step 7: Return standardized response
        return new PaymentsResponseDTO(
                effectiveReference,
                actualGatewayName,
                request.paymentDetails().amount(),
                currencyCode,
                gatewayResponse.fee() != null ? gatewayResponse.fee() : BigDecimal.ZERO,
                gatewayResponse.totalCharged() != null ? gatewayResponse.totalCharged() : request.paymentDetails().amount(),
                gatewayResponse.status(),
                paymentChannel,
                null,
                null,
                Instant.now()
        );
    }

    /**
     * Persists a transaction record in the database.
     */
    private void saveTransaction(
            UUID senderId,
            UUID receiverId,
            UUID senderWalletId,
            UUID receiverWalletId,
            String gatewayAccountId,
            BigDecimal amount,
            String currencyCode,
            BigDecimal feeAmount,
            String status,
            String referenceCode,
            String metaData
    ) {
        // Use the canonical TransactionModel from the transactions module
        com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.model.TransactionModel transaction =
                new com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.model.TransactionModel();
        transaction.setUserId(senderId);
        transaction.setAmount(amount);
        transaction.setCurrency(currencyCode);
        transaction.setTransactionType("DISBURSEMENT");
        transaction.setStatus(status);
        transaction.setGateway(gatewayAccountId);
        transaction.setReference(referenceCode);
        transaction.setGatewayReference(referenceCode);
        transaction.setDescription(metaData);
        transaction.setMetadata(metaData);

        transactionRepository.save(transaction);
    }
}