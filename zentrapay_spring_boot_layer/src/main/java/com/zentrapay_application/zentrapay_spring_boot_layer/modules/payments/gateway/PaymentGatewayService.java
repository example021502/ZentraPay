package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.gateway;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.DisbursementRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.PaymentsResponseDTO;

/**
 * Common interface for all payment gateway integrations.
 * <p>
 * Provides a contract for disbursement operations across different providers:
 * <ul>
 *   <li>{@link PaystackGatewayService} - Primary gateway for Ghanaian national transactions</li>
 *   <li>{@link OnafriqGatewayService} - International transactions gateway</li>
 *   <li>{@link FlutterwaveGatewayService} - Secondary/failover gateway for both national and international</li>
 * </ul>
 * <p>
 * Implementations should handle gateway-specific logic (authentication, request formatting,
 * response mapping, etc.) and return a standardized {@link PaymentsResponseDTO}.
 */
public interface PaymentGatewayService {

    /**
     * Initiates a disbursement through the payment gateway.
     * <p>
     * This method should:
     * <ol>
     *   <li>Map internal DTO to gateway-specific request format</li>
     *   <li>Authenticate with the gateway API</li>
     *   <li>Create transfer recipient if needed</li>
     *   <li>Initiate the transfer</li>
     *   <li>Map gateway response to standard {@link PaymentsResponseDTO}</li>
     * </ol>
     *
     * @param request The disbursement request with all necessary payment details
     * @return Standardized payment response containing reference, status, amount, etc.
     */
    PaymentsResponseDTO processDisbursement(DisbursementRequestDTO request);

    /**
     * Returns the name of the payment gateway (e.g., "Paystack", "Flutterwave", "Onafriq").
     * Used for logging, transaction records, and identification.
     */
    String getGatewayName();

    /**
     * Indicates whether this gateway supports the given currency.
     * Useful for routing decisions in the gateway factory.
     */
    boolean supportsCurrency(String currencyCode);

    /**
     * Indicates whether this gateway is currently operational.
     * Can be used to check API health before routing to this gateway.
     */
    boolean isOperational();
}