package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.gateway;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.DisbursementRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.PaymentsResponseDTO;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Factory component responsible for routing disbursement requests to the appropriate payment gateway.
 * <p>
 * Gateway routing strategy:
 * <ol>
 *   <li><strong>Paystack (PRIMARY)</strong> - Used for all Ghanaian national transactions (GHS currency).
 *       Paystack is the default and preferred gateway for Ghana.</li>
 *   <li><strong>Onafriq (INTERNATIONAL)</strong> - Used for cross-border/international transactions.
 *       Onafriq specializes in remittances across African borders.</li>
 *   <li><strong>Flutterwave (FAILOVER)</strong> - Secondary gateway that serves as backup for both
 *       national and international transactions when primary gateways fail or are unavailable.</li>
 * </ol>
 * <p>
 * The factory evaluates each request and selects the optimal gateway based on:
 * <ul>
 *   <li>Transaction type (national vs international)</li>
 *   <li>Currency support</li>
 *   <li>Gateway operational status</li>
 *   <li>Failover chain availability</li>
 * </ul>
 * <p>
 * All gateway calls happen within the {@link org.springframework.transaction.annotation.Transactional}
 * boundary of {@link com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.services.PaymentsServices},
 * ensuring that transaction records are persisted atomically with wallet debits/credits.
 */
@Component
public class PaymentGatewayFactory {

    private static final Logger log = LoggerFactory.getLogger(PaymentGatewayFactory.class);

    private final PaystackGatewayService paystackGatewayService;
    private final OnafriqGatewayService onafriqGatewayService;
    private final FlutterwaveGatewayService flutterwaveGatewayService;

    public PaymentGatewayFactory(
            PaystackGatewayService paystackGatewayService,
            OnafriqGatewayService onafriqGatewayService,
            FlutterwaveGatewayService flutterwaveGatewayService) {
        this.paystackGatewayService = paystackGatewayService;
        this.onafriqGatewayService = onafriqGatewayService;
        this.flutterwaveGatewayService = flutterwaveGatewayService;
    }

    /**
     * Routes a disbursement request to the appropriate payment gateway with automatic failover.
     * <p>
     * Routing logic:
     * <ol>
     *   <li>If transaction is international (isInternational=true), try Onafriq first, then Flutterwave</li>
     *   <li>If transaction is Ghanaian national (currency=GHS), try Paystack first, then Flutterwave</li>
     *   <li>For other national transactions, try Paystack first, then Flutterwave</li>
     *   <li>If all gateways fail, throw the last exception</li>
     * </ol>
     *
     * @param request The disbursement request containing payment details
     * @return Standardized payment response from the successful gateway
     * @throws RuntimeException if all available gateways fail to process the transaction
     */
    public PaymentsResponseDTO processDisbursement(DisbursementRequestDTO request) {
        String currencyCode = request.paymentDetails().sourceCurrency();
        boolean isInternational = request.paymentDetails().isInternational();
        String gatewayName;

        log.info("[GATEWAY_FACTORY] Routing disbursement: userId={}, amount={} {}, isInternational={}",
                request.userId(), request.paymentDetails().amount(), currencyCode, isInternational);

        // Determine gateway chain based on transaction type
        List<PaymentGatewayService> gatewayChain = resolveGatewayChain(isInternational, currencyCode);

        // Try each gateway in sequence until one succeeds
        Exception lastException = null;
        for (PaymentGatewayService gateway : gatewayChain) {
            if (!gateway.isOperational()) {
                log.warn("[GATEWAY_FACTORY] Gateway {} is not operational, skipping", gateway.getGatewayName());
                continue;
            }

            if (!gateway.supportsCurrency(currencyCode)) {
                log.warn("[GATEWAY_FACTORY] Gateway {} does not support currency {}, skipping",
                        gateway.getGatewayName(), currencyCode);
                continue;
            }

            try {
                log.info("[GATEWAY_FACTORY] Attempting disbursement via {}", gateway.getGatewayName());
                PaymentsResponseDTO response = gateway.processDisbursement(request);
                log.info("[GATEWAY_FACTORY] Successfully processed via {}: ref={}",
                        gateway.getGatewayName(), response.transactionReference());
                return response;

            } catch (Exception e) {
                lastException = e;
                log.error("[GATEWAY_FACTORY] Gateway {} failed: error={}", gateway.getGatewayName(), e.getMessage());
                // Continue to next gateway in chain
            }
        }

        // All gateways failed
        log.error("[GATEWAY_FACTORY] All gateways failed for disbursement: userId={}, amount={} {}",
                request.userId(), request.paymentDetails().amount(), currencyCode);

        if (lastException != null) {
            throw new RuntimeException(
                    "All payment gateways failed to process disbursement. Last error: " + lastException.getMessage(),
                    lastException);
        } else {
            throw new RuntimeException("No payment gateways available to process disbursement");
        }
    }

    /**
     * Determines the ordered list of gateways to try based on transaction characteristics.
     * <p>
     * Gateway priority:
     * <ul>
     *   <li><strong>International transactions:</strong> Onafriq → Flutterwave</li>
     *   <li><strong>Ghana national (GHS):</strong> Paystack → Flutterwave</li>
     *   <li><strong>Other national:</strong> Paystack → Flutterwave</li>
     * </ul>
     */
    private List<PaymentGatewayService> resolveGatewayChain(boolean isInternational, String currencyCode) {
        if (isInternational) {
            // International transactions: prioritize Onafriq, failover to Flutterwave
            log.info("[GATEWAY_FACTORY] Routing to international gateway chain: Onafriq → Flutterwave");
            return List.of(onafriqGatewayService, flutterwaveGatewayService);
        } else {
            // National transactions
            if ("GHS".equalsIgnoreCase(currencyCode)) {
                // Ghanaian national transactions: Paystack is primary, Flutterwave is failover
                log.info("[GATEWAY_FACTORY] Routing to Ghanaian national gateway chain: Paystack → Flutterwave");
                return List.of(paystackGatewayService, flutterwaveGatewayService);
            } else {
                // Other national transactions: Paystack primary, Flutterwave failover
                log.info("[GATEWAY_FACTORY] Routing to national gateway chain: Paystack → Flutterwave");
                return List.of(paystackGatewayService, flutterwaveGatewayService);
            }
        }
    }

    /**
     * Returns the primary gateway name for a given transaction type and currency.
     * Used for informational purposes, logging, and transaction history when
     * the response does not explicitly indicate which gateway was used.
     *
     * @param isInternational Whether the transaction is cross-border
     * @param currencyCode    The currency being transacted
     * @return The name of the primary gateway for this transaction type
     */
    public String getPrimaryGatewayName(boolean isInternational, String currencyCode) {
        if (isInternational) {
            return "Onafriq";
        } else if ("GHS".equalsIgnoreCase(currencyCode)) {
            return "Paystack";
        } else {
            return "Paystack";
        }
    }
}
