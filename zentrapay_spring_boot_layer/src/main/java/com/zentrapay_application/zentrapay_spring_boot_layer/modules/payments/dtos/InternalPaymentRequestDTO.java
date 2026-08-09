package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * {@code POST /api/payments/internal} request body (API contract §6):
 * {@code {pin,recipient:{phoneNumber?,zentag?},amount,currencyCode}}.
 */
public record InternalPaymentRequestDTO(
        @NotBlank(message = "PIN is required for authorization")
        String pin,

        @Valid
        @NotNull(message = "Amount details are required")
        InternalAmountDTO amountDetails,

        @Valid
        @NotNull(message = "Recipient details are required")
        InternalRecipientDTO recipientDetails


) {
}
