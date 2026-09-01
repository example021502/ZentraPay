package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

/**
 * POST /api/payments/initialize — customer checkout (inbound wallet funding).
 * The authenticated caller is the payer; {@code email} is optional and
 * defaults to the JWT user's email. {@code currencyCode} selects the
 * corridor: the gateway is resolved from it (national -> PAYSTACK,
 * international -> ONAFRIQ, failover -> FLUTTERWAVE).
 */
public record InitializePaymentRequestDTO(
        @NotNull(message = "Amount is required")
        @DecimalMin(value = "0.50", message = "Amount must be at least 0.50")
        Long amount,
        @NotBlank(message = "Currency code is required")
        String currencyCode,
        /** Optional — falls back to the authenticated user's email. */
        String email,
        /** Optional narration shown on the gateway checkout page. */
        String purpose
) {
}