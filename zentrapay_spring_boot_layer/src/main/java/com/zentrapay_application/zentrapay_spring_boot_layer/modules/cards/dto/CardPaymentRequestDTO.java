package com.zentrapay_application.zentrapay_spring_boot_layer.modules.cards.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.math.BigDecimal;

public record CardPaymentRequestDTO(
        @NotNull(message = "Amount is required")
        @Positive(message = "Amount must be positive")
        BigDecimal amount,

        @NotBlank(message = "Currency code is required")
        String currencyCode,

        @NotBlank(message = "Merchant name is required")
        String merchantName,

        @NotBlank(message = "Method is required (NFC or QR)")
        String method
) {
}
