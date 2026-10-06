package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dto;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.Datatypes;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * POST /api/payments/initialize — customer checkout (inbound wallet funding).
 * The authenticated caller is the payer; {@code email} is optional and
 * defaults to the JWT user's email. {@code currencyCode} selects the
 * corridor: the gateway is resolved from it (national -> PAYSTACK,
 * international -> ONAFRIQ, failover -> FLUTTERWAVE).
 */
public record RecipientDetailsRequestDTO(
        @NotNull(message = "Recipient name is required")
        String name,
        String zentag,
        String phoneNumber,
        String accountNumber,
        String id,
        @NotNull(message = "Recipient type is required")
        Datatypes.RecipientType type
) {
}