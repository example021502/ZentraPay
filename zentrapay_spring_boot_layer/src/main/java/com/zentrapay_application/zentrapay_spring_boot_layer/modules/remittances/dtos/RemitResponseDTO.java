package com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittances.dtos;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/** POST /api/remit + GET /api/remit/history item — one cross-border send. */
public record RemitResponseDTO(
        UUID remittanceId,
        UUID transactionId,
        String reference,
        String recipientName,
        String recipientCountryCode,
        String sourceCurrencyCode,
        String destinationCurrencyCode,
        BigDecimal amount,
        BigDecimal destinationAmount,
        BigDecimal exchangeRate,
        BigDecimal fee,
        String status,
        String channel,
        LocalDateTime createdAt
) {
}