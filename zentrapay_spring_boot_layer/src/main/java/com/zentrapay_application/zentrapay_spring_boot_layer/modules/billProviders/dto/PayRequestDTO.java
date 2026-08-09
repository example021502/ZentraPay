package com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.util.UUID;

public record PayRequestDTO(
        @NotBlank(message = "pin is required")
        String pin,

        @NotNull(message = "providerId is required")
        UUID providerId,

        @NotBlank(message = "customerReference is required")
        String customerReference,

        @NotNull(message = "amount is required")
        @DecimalMin(value = "0.01", message = "amount must be positive")
        BigDecimal amount,

        @NotBlank(message = "currencyCode is required")
        String currencyCode
) {
}
