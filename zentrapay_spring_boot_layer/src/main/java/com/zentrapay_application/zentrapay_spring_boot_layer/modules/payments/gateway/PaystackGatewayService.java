package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.gateway;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.DisbursementRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.PaymentsResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.paystack.PaystackService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * Paystack gateway implementation — PRIMARY gateway for all Ghanaian national transactions.
 * <p>
 * Paystack is the preferred gateway for:
 * <ul>
 *   <li>All disbursements within Ghana (GHS currency)</li>
 *   <li>Mobile money transfers to Ghanaian networks (MTN, Vodafone, AirtelTigo)</li>
 *   <li>Bank transfers via GHIPSS network</li>
 * </ul>
 * <p>
 * This implementation wraps the existing {@link PaystackService} to conform to the
 * {@link PaymentGatewayService} interface, enabling consistent routing through the gateway factory.
 */
@Service
public class PaystackGatewayService implements PaymentGatewayService {

    private static final Logger log = LoggerFactory.getLogger(PaystackGatewayService.class);

    private final PaystackService paystackService;

    public PaystackGatewayService(PaystackService paystackService) {
        this.paystackService = paystackService;
    }

    /**
     * Processes a disbursement through Paystack.
     * <p>
     * Delegates to the underlying {@link PaystackService} which handles:
     * <ol>
     *   <li>Recipient creation on Paystack</li>
     *   <li>Transfer initiation</li>
     *   <li>Response mapping to standard format</li>
     * </ol>
     *
     * @param request The validated disbursement request
     * @return Standardized payment response with Paystack-specific details
     */
    @Override
    public PaymentsResponseDTO processDisbursement(DisbursementRequestDTO request) {
        log.info("[PAYSTACK_GATEWAY] Processing disbursement: userId={}, amount={} {}",
                request.userId(),
                request.paymentDetails().amount(),
                request.paymentDetails().sourceCurrency());
        // ====================================================================
        // >>> ACTUAL PAYSTACK PAYMENT API CALL <<<
        // Delegates to PaystackService.processDisbursement() which calls:
        //   - POST /transferrecipient  (create recipient)
        //   - POST /transfer           (initiate transfer)
        // Both call Paystack's REST API via a RestTemplate owned by PaystackService
        // See: PaystackService.java  lines 76-113
        // ====================================================================
        return paystackService.processDisbursement(request);
    }

    /**
     * Returns the gateway name for identification in logs and transaction records.
     */
    @Override
    public String getGatewayName() {
        return "Paystack";
    }

    /**
     * Paystack supports a wide range of African currencies including GHS, NGN, ZAR, USD, KES, etc.
     */
    @Override
    public boolean supportsCurrency(String currencyCode) {
        if (currencyCode == null || currencyCode.isBlank()) {
            return false;
        }
        // Major African currencies supported by Paystack
        return switch (currencyCode.toUpperCase()) {
            case "GHS", "NGN", "ZAR", "USD", "KES", "UGX", "TZS", "XOF", "XAF" -> true;
            default -> false;
        };
    }

    /**
     * Paystack is operational if the underlying service is available.
     * This can be enhanced with actual health check calls to Paystack API.
     */
    @Override
    public boolean isOperational() {
        // ====================================================================
        // >>> ACTUAL PAYSTACK HEALTH CHECK API CALL <<<
        // TODO: Implement actual health check by calling Paystack API
        // e.g. GET https://api.paystack.co/balance
        // ====================================================================
        // For now, assume operational if service is instantiated
        return paystackService != null;
    }
}