package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

/**
 * Shared {@code {amount}} request body — used by savings deposit/withdraw and loan
 * repayment (API_CONTRACT.md §13).
 */
public record AmountRequestDTO(
        @NotNull(message = "amount is required")
        @DecimalMin(value = "0.01", message = "amount must be positive")
        BigDecimal amount
) {
}
