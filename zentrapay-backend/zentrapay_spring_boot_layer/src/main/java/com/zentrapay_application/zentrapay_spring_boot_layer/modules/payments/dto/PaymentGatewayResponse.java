package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dto;

import java.math.BigDecimal;

/**
 * Response DTO from payment gateway processing.
 */
public record PaymentGatewayResponse(
        boolean success,
        String reference,
        String gatewayReference,
        String gatewayName,
        BigDecimal amount,
        String currency,
        String status,
        String failureReason,
        String authorizationUrl,
        String accessCode
) {
}