package com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittance.dtos;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

public record RemittanceHistoryDTO(
        UUID remittanceId,
        BigDecimal amount,
        String sourceCurrencyCode,
        String destinationCurrencyCode,
        String recipientName,
        String status,
        LocalDateTime createdAt
) {
}
