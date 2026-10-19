package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto;

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
