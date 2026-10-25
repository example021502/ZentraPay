package com.zentrapay.backend.dto.zgrow;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/** One currency bucket of GET /api/zgrow/savings (source of the hero total). */
public record SavingsSummaryDTO(
        String currencyCode,
        BigDecimal totalAmount,
        Long entryCount,
        LocalDateTime lastSavedAt
) {
}
