package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * {@code POST /api/payments/bank-transfer} request body (API contract §6):
 * {@code {pin, recipientDetails, amountDetails, channelCode, description?}}.
 * <p>
 * Standardized payload structure matching the frontend collection pattern:
 * - recipientDetails: nested object with account information (ExternalRecipientDTO)
 * - amountDetails: nested object with amount and currency (ExternalAmountDTO)
 * - pin: authentication
 * - channelCode: payment channel identifier
 * - userId: extracted from JWT token
 */
public record BankTransferRequestDTO(
        @NotBlank(message = "PIN is required for authorization")
        String pin,

        @Valid
        @NotNull(message = "Recipient details are required")
        ExternalRecipientDTO recipientDetails,

        @Valid
        @NotNull(message = "Amount details are required")
        ExternalAmountDTO amountDetails,

        @NotBlank(message = "Channel code is required")
        String channelCode,

        String description
) {
}