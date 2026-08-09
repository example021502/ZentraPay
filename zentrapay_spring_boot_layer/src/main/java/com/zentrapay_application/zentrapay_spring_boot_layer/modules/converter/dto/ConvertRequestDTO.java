package com.zentrapay_application.zentrapay_spring_boot_layer.modules.converter.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

public record ConvertRequestDTO(
        @NotBlank(message = "from is required")
        String from,

        @NotBlank(message = "to is required")
        String to,

        @NotNull(message = "amount is required")
        @DecimalMin(value = "0.00000001", message = "amount must be positive")
        BigDecimal amount
) {
}
