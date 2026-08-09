package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * Standardized external payment request DTO (API contract §6):
 * {@code {pin, recipientDetails, amountDetails}}
 * <p>
 * Used for payments to external networks (banks, mobile money providers, etc.).
 * The providerType is determined by the endpoint path (e.g., /bank-transfer,
 * /mobile-money, /external/{providerType}) and set by the controller.
 * userId is extracted from JWT token authentication, not from the request body.
 */
public record ExternalPaymentRequestDTO(
        @NotBlank(message = "PIN is required for authorization")
        String pin,

        @Valid
        @NotNull(message = "Recipient details are required")
        ExternalRecipientDTO recipientDetails,

        @Valid
        @NotNull(message = "Amount details are required")
        ExternalAmountDTO amountDetails,

        String providerType
) {
}