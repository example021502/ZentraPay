package com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittance.dtos;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

/**
 * Amount details for remittance payments (API contract §12):
 * {@code {amount, sourceCurrencyCode, destinationCurrencyCode, channel}}
 */
public record AmountDetailsDTO(
        @NotNull(message = "Amount is required")
        @DecimalMin(value = "0.01", message = "Amount must be positive")
        BigDecimal amount,

        @NotBlank(message = "Source currency code is required")
        String sourceCurrencyCode,

        @NotBlank(message = "Destination currency code is required")
        String destinationCurrencyCode,

        @NotBlank(message = "Channel is required")
        String channel
) {
}
