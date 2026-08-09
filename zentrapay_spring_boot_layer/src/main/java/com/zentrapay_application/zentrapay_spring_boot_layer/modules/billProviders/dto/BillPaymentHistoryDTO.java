package com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

public record BillPaymentHistoryDTO(
        UUID paymentId,
        String providerName,
        String customerReference,
        BigDecimal amount,
        String currencyCode,
        String status,
        LocalDateTime createdAt
) {
}
