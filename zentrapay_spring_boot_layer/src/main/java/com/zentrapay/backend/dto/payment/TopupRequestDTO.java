package com.zentrapay.backend.dto.payment;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

/**
 * POST /api/topup/paystack and /api/topup/flutterwave - start a wallet top-up on ONE gateway.
 * {@code source} / {@code paymentMethod} are what the user picked on the top-up screen; the hosted
 * checkout offers the matching channels itself, so they are informational here.
 */
public record TopupRequestDTO(
        @NotNull(message = "Amount is required")
        @DecimalMin(value = "1.00", message = "Amount must be at least 1.00")
        BigDecimal amount,
        @NotBlank(message = "Currency code is required")
        String currencyCode,
        String source,
        String paymentMethod,
        // keep the card the customer pays with, to charge it later without a checkout
        Boolean saveCard
) {
}
