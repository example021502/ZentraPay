package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

/**
 * DTO for loan application — API_CONTRACT.md §13: {@code {amount,currencyCode,termMonths}}.
 */
public record LoanRequestDTO(
        @NotNull(message = "amount is required")
        @DecimalMin(value = "1.0", message = "Minimum loan amount is 1.0")
        BigDecimal amount,

        @NotBlank(message = "currencyCode is required")
        String currencyCode,

        @NotNull(message = "termMonths is required")
        Integer termMonths
) {
}
