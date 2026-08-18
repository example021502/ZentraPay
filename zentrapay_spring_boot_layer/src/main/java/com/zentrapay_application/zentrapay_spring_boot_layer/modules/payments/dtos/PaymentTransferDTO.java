package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

// EXTRACTING THE TRANSFER DETAILS
public record TransferDTO(
    @NotBlank(message = "Reference Id missing") String referenceId,
    @NotNull(message = "Amount missing")
    @DecimalMin(value = "0.01", message = "Amount must be positive")
    BigDecimal amount,
    @NotBlank(message = "Currency code missing") String currencyCode
) {
}
