package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Response for POST /api/payments/initialize — everything the Flutter client
 * needs to hand the payer off to the gateway's hosted checkout page.
 */
public record InitializePaymentResponseDTO(
        UUID transactionId,
        /** Gateway that owns this checkout: paystack | onafriq | flutterwave. */
        String gateway,
        String reference,
        String authorizationUrl,
        String accessCode,
        BigDecimal amount,
        String currencyCode,
        String status
) {
}