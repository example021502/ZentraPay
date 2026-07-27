package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Response DTO for savings account details.
 */
public record SavingsResponseDTO(
        UUID savingsId,
        UUID userId,
        String savingsName,
        BigDecimal balance,
        String currency,
        String description,
        LocalDate targetDate,
        BigDecimal targetAmount,
        String status,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}