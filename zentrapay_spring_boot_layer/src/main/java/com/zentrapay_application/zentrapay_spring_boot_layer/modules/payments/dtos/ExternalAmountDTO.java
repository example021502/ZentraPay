package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

/**
 * External payment amount details (API contract §6):
 * {@code {amount, currencyCode, destinationCurrencyCode?, description?}}
 * <p>
 * Standardized payload structure: recipientDetails, amountDetails, pin
 */
public record ExternalAmountDTO(
        @NotNull(message = "Amount is required")
        @DecimalMin(value = "0.01", message = "Amount must be positive")
        BigDecimal amount,

        @NotBlank(message = "Currency code is required")
        String currencyCode,

        String destinationCurrencyCode,

        String description
) {
}