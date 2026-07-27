package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.math.BigDecimal;

/**
 * Internal payment details for wallet-to-wallet transfers.
 * <p>
 * Mirrors the Node.js layer's paymentDetails object for internal payments:
 * <pre>
 * { "amount": 5000, "currencyCode": "NGN" }
 * </pre>
 */
public record InternalPaymentDetailsDTO(

        @NotNull(message = "Amount is required")
        @Positive(message = "Amount must be positive")
        BigDecimal amount,

        @NotNull(message = "Currency code is required")
        String currencyCode

) {
}