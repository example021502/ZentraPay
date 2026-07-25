package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import java.math.BigDecimal;
import java.time.Instant;

public record PaymentsResponseDTO(
        String transactionReference,
        String gatewayName,
        BigDecimal amount,
        String currencyCode,
        BigDecimal fee,
        BigDecimal totalCharged,
        String status,
        String paymentChannel,
        String authorizationUrl,
        String accessCode,
        Instant expiresAt
) {
}