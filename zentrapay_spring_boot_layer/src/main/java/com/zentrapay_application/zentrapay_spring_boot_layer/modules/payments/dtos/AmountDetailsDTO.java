package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

/**
 * {@code POST /api/payments/internal} amount shape (API contract §6):
 * {@code {amount,currencyCode}} — the sender's and receiver's wallets are looked
 * up by this same {@code currencyCode}, so there's no destination-currency
 * money is landing.
 */
public record AmountDetailsDTO(
        @NotNull(message = "Amount is required")
        @DecimalMin(value = "0.01", message = "Amount must be positive")
        BigDecimal amount,

        @NotBlank(message = "Currency code is required")
        String currencyCode
) {
}
