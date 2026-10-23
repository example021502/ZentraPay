package com.zentrapay.backend.dto.bill;

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
