package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * DTO for creating a new savings account.
 */
public record SavingsRequestDTO(
        @NotBlank(message = "Savings name is required")
        String savingsName,

        @NotNull(message = "Initial deposit is required")
        @DecimalMin(value = "10.0", message = "Minimum initial deposit is 10.0")
        BigDecimal initialDeposit,

        @NotBlank(message = "Currency is required")
        String currency,

        String description,

        LocalDate targetDate,

        BigDecimal targetAmount
) {
}