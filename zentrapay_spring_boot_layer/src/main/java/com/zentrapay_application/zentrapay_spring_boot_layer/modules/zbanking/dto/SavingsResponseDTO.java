package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Response DTO for savings account details — API_CONTRACT.md §13.
 */
public record SavingsResponseDTO(
        UUID savingsId,
        String savingsName,
        String currencyCode,
        BigDecimal balance,
        BigDecimal targetAmount,
        LocalDate targetDate,
        String status
) {
}
