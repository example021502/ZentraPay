package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * DTO for creating a new savings account — API_CONTRACT.md §13.
 */
public record SavingsRequestDTO(
        @NotBlank(message = "Savings name is required")
        String savingsName,

        @NotBlank(message = "Currency is required")
        String currencyCode,

        @NotNull(message = "Initial deposit is required")
        @DecimalMin(value = "0.0", message = "Initial deposit cannot be negative")
        BigDecimal initialDeposit,

        BigDecimal targetAmount,

        LocalDate targetDate,

        String description
) {
}
