package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

// EXTRACTING THE TRANSFER DETAILS
public record PaymentTransferDTO(
    @NotBlank(message = "Reference Id missing")
    @Valid
    String referenceId,
    @NotNull(message = "Amount missing")
    @DecimalMin(value = "0.01", message = "Amount must be positive")
    BigDecimal amount,
//  currency code
    @NotBlank(message = "Currency code missing")
    @Valid
    String currencyCode,
//  currency type, crypto / fiat currency
    @NotBlank(message = "Currency type missing")
    @Valid
    String currencyType,
    String purpose
) {
}
