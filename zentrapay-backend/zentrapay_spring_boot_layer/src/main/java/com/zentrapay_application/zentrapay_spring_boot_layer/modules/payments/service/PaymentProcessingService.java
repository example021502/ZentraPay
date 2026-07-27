package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dto.PaymentGatewayResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dto.PaymentRequest;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.gateway.PaymentGatewayFactory;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.gateway.PaymentGatewayService;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.model.TransactionModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.repository.TransactionRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.model.FiatBalancesModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.repository.CryptoBalancesRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.repository.FiatBalancesRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Map;
import java.util.UUID;

/**
 * Central payment processing service that orchestrates transactions across multiple gateways.
 * <p>
 * Gateway selection strategy:
 * - Ghanaian national transactions → Paystack (primary)
 * - International transactions → Onafriq (primary)
 * - Failover for any transaction → Flutterwave (secondary)
 * <p>
 * All payment processing and transaction recording happens within a single @Transactional boundary.
 */
@Service
@Transactional
public class PaymentProcessingService {

    private static final Logger log = LoggerFactory.getLogger(PaymentProcessingService.class);

    private final PaymentGatewayFactory gatewayFactory;
    private final TransactionRepository transactionRepository;
    private final FiatBalancesRepository fiatBalancesRepository;
    private final CryptoBalancesRepository cryptoBalancesRepository;

    public PaymentProcessingService(
            PaymentGatewayFactory gatewayFactory,
            TransactionRepository transactionRepository,
            FiatBalancesRepository fiatBalancesRepository,
            CryptoBalancesRepository cryptoBalancesRepository) {
        this.gatewayFactory = gatewayFactory;
        this.transactionRepository = transactionRepository;
        this.fiatBalancesRepository = fiatBalancesRepository;
        this.cryptoBalancesRepository = cryptoBalancesRepository;
    }

    /**
     * Process a payment with automatic gateway selection and transaction recording.
     *
     * @param userId  The user initiating the payment
     * @param request The payment request details
     * @return TransactionModel with the recorded transaction
     */
    public TransactionModel processPayment(UUID userId, PaymentRequest request) {
        log.info("[PAYMENT] Processing payment for userId={}, amount={} {}",
                userId, request.amount(), request.currency());

        // Convert metadata Map to JSON string for storage
        String metadataJson = convertMetadataToJson(request.metadata());

        // 1. Determine the appropriate gateway based on transaction characteristics
        boolean isInternational = !"GH".equalsIgnoreCase(request.country());
        String primaryGateway = gatewayFactory.getPrimaryGatewayName(isInternational, request.currency());

        log.info("[PAYMENT] Selected gateway: {}", primaryGateway);

        try {
            // 2. Process payment via the selected gateway
            PaymentGatewayResponse gatewayResponse = processViaGateway(
                    primaryGateway, userId, request, metadataJson
            );

            // 3. Record transaction in database (guaranteed by @Transactional)
            TransactionModel transaction = recordTransaction(userId, request, gatewayResponse, metadataJson);

            // 4. Update wallet balances atomically
            updateWalletBalances(userId, request, transaction);

            log.info("[PAYMENT] Payment processed successfully. Transaction ID: {}", transaction.getTransactionId());
            return transaction;

        } catch (Exception e) {
            log.error("[PAYMENT] Payment failed with {}. Attempting failover...",
                    primaryGateway, e);

            // 5. Automatic failover to Flutterwave
            return processWithFailover(userId, request, metadataJson, e);
        }
    }

    /**
     * Process payment via the specified gateway.
     * <p>
     * ========================================================================
     * >>> ACTUAL GATEWAY PAYMENT LOGIC NEEDS TO BE IMPLEMENTED HERE <<<
     * ========================================================================
     * This is where the actual HTTP API call to the selected payment gateway
     * (Paystack, Onafriq, or Flutterwave) should be made.
     * <p>
     * What needs to happen here:
     * <ol>
     *   <li>Based on <code>gatewayName</code>, select the appropriate gateway service:
     *       <ul>
     *         <li>"Paystack"    → inject {@code PaystackGatewayService} and call {@code processDisbursement()}</li>
     *         <li>"Onafriq"     → inject {@code OnafriqGatewayService} and call {@code processDisbursement()}</li>
     *         <li>"Flutterwave" → inject {@code FlutterwaveGatewayService} and call {@code processDisbursement()}</li>
     *       </ul>
     *   </li>
     *   <li>Map the {@link PaymentRequest} to a {@code DisbursementRequestDTO}</li>
     *   <li>Call the gateway's {@code processDisbursement()} which will make the actual HTTP API call</li>
     *   <li>Map the gateway's response to {@link PaymentGatewayResponse}</li>
     *   <li>Handle any gateway-specific errors or timeouts</li>
     * </ol>
     * <p>
     * Reference implementations of the actual API calls can be found in:
     * <ul>
     *   <li>{@code PaystackGatewayService.processDisbursement()} → delegates to {@code PaystackService.processDisbursement()}</li>
     *   <li>{@code OnafriqGatewayService.processDisbursement()}  → calls Onafriq API via RestTemplate</li>
     *   <li>{@code FlutterwaveGatewayService.processDisbursement()} → calls Flutterwave API via RestTemplate</li>
     * </ul>
     * ========================================================================
     */
    private PaymentGatewayResponse processViaGateway(String gatewayName, UUID userId, PaymentRequest request, String metadataJson) {
        // TODO: Implement the actual gateway routing and HTTP API call here.
        // See the detailed comment above for what needs to happen.
        // 
        // Example:
        //   DisbursementRequestDTO disbursementRequest = mapToDisbursementRequest(userId, request);
        //   if ("Paystack".equals(gatewayName)) {
        //       PaymentsResponseDTO resp = paystackGatewayService.processDisbursement(disbursementRequest);
        //       return mapToPaymentGatewayResponse(resp);
        //   } else if ("Onafriq".equals(gatewayName)) {
        //       PaymentsResponseDTO resp = onafriqGatewayService.processDisbursement(disbursementRequest);
        //       return mapToPaymentGatewayResponse(resp);
        //   } else if ("Flutterwave".equals(gatewayName)) {
        //       PaymentsResponseDTO resp = flutterwaveGatewayService.processDisbursement(disbursementRequest);
        //       return mapToPaymentGatewayResponse(resp);
        //   }
        
        // TEMPORARY: Mock response — replace with actual gateway call above
        return new PaymentGatewayResponse(
                true,
                "REF-" + UUID.randomUUID().toString().substring(0, 8),
                "GATEWAY-" + UUID.randomUUID().toString().substring(0, 8),
                gatewayName,
                request.amount(),
                request.currency(),
                "COMPLETED",
                null,
                null,
                null
        );
    }

    /**
     * Process payment with Flutterwave as failover gateway.
     */
    private TransactionModel processWithFailover(UUID userId, PaymentRequest request, String metadataJson, Exception originalError) {
        log.warn("[PAYMENT] Initiating failover to Flutterwave for userId={}", userId);

        try {
            PaymentGatewayResponse gatewayResponse = processViaGateway(
                    "Flutterwave", userId, request, metadataJson
            );

            TransactionModel transaction = recordTransaction(userId, request, gatewayResponse, metadataJson);
            transaction.setGateway("Flutterwave");
            transaction.setStatus("COMPLETED_WITH_FAILOVER");

            updateWalletBalances(userId, request, transaction);

            log.info("[PAYMENT] Failover successful. Transaction ID: {}", transaction.getTransactionId());
            return transaction;

        } catch (Exception failoverError) {
            log.error("[PAYMENT] Failover also failed for userId={}", userId, failoverError);
            throw new RuntimeException(
                    "Payment failed with both primary and failover gateways. Primary error: " + originalError.getMessage()
                    + ". Failover error: " + failoverError.getMessage());
        }
    }

    /**
     * Record transaction in the transactions table.
     * This method is called within the @Transactional boundary of processPayment.
     */
    private TransactionModel recordTransaction(UUID userId, PaymentRequest request,
                                               PaymentGatewayResponse gatewayResponse, String metadataJson) {
        TransactionModel transaction = new TransactionModel();
        transaction.setUserId(userId);
        transaction.setAmount(request.amount());
        transaction.setCurrency(request.currency());
        transaction.setTransactionType(request.transactionType());
        transaction.setStatus(gatewayResponse.success() ? "COMPLETED" : "FAILED");
        transaction.setGateway(gatewayResponse.gatewayName());
        transaction.setReference(gatewayResponse.reference());
        transaction.setGatewayReference(gatewayResponse.gatewayReference());
        transaction.setCustomerEmail(request.customerEmail());
        transaction.setCustomerPhone(request.customerPhone());
        transaction.setDescription(request.description());
        transaction.setMetadata(metadataJson);

        if (gatewayResponse.failureReason() != null) {
            transaction.setFailureReason(gatewayResponse.failureReason());
        }

        return transactionRepository.save(transaction);
    }

    /**
     * Update wallet balances based on transaction type.
     * This method is called within the same @Transactional boundary.
     */
    private void updateWalletBalances(UUID userId, PaymentRequest request, TransactionModel transaction) {
        if (!"COMPLETED".equals(transaction.getStatus()) &&
                !"COMPLETED_WITH_FAILOVER".equals(transaction.getStatus())) {
            return; // Don't update balances for failed transactions
        }

        switch (request.transactionType()) {
            case "DEPOSIT", "CREDIT" -> {
                // Credit user's wallet
                FiatBalancesModel fiatBalance = fiatBalancesRepository.findByUserIdAndCurrency(
                        userId, request.currency()).orElseGet(() -> {
                    FiatBalancesModel newBalance = new FiatBalancesModel();
                    newBalance.setUserId(userId);
                    newBalance.setCurrency(request.currency());
                    newBalance.setBalance(BigDecimal.ZERO);
                    return newBalance;
                });
                fiatBalance.setBalance(fiatBalance.getBalance().add(request.amount()));
                fiatBalancesRepository.save(fiatBalance);
            }

            case "WITHDRAWAL", "DEBIT" -> {
                // Debit user's wallet
                FiatBalancesModel fiatBalance = fiatBalancesRepository.findByUserIdAndCurrency(
                        userId, request.currency()).orElseThrow(() -> new RuntimeException("Insufficient balance"));

                if (fiatBalance.getBalance().compareTo(request.amount()) < 0) {
                    throw new RuntimeException("Insufficient balance");
                }

                fiatBalance.setBalance(fiatBalance.getBalance().subtract(request.amount()));
                fiatBalancesRepository.save(fiatBalance);
            }

            case "CRYPTO_PURCHASE" -> {
                // Handle crypto purchases
                // TODO: Implement crypto balance updates
            }

            default -> log.warn("[PAYMENT] Unhandled transaction type: {}", request.transactionType());
        }
    }

    /**
     * Helper method to convert metadata Map to JSON string for storage.
     */
    private String convertMetadataToJson(Map<String, Object> metadata) {
        if (metadata == null || metadata.isEmpty()) {
            return null;
        }
        // Simple conversion - in production, use ObjectMapper or similar
        return metadata.toString();
    }
}