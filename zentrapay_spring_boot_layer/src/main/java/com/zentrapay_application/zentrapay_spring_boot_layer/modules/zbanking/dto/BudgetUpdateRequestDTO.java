package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

public record BudgetUpdateRequestDTO(
        @NotNull(message = "monthlyLimit is required")
        @DecimalMin(value = "0.0", message = "monthlyLimit cannot be negative")
        BigDecimal monthlyLimit
) {
}
