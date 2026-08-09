package com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittance.dtos;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * {@code POST /api/remittance/send} request body (API contract §12):
 * {@code {pin, recipientDetails, amountDetails}}
 * <p>
 * userId is extracted from JWT token authentication, not from request body.
 */
public record SendRequestDTO(
        @NotBlank(message = "PIN is required for authorization")
        String pin,

        @Valid
        @NotNull(message = "Recipient details are required")
        RemittanceRecipientDTO recipientDetails,

        @Valid
        @NotNull(message = "Amount details are required")
        RemittanceAmountDTO amountDetails
) {
}
