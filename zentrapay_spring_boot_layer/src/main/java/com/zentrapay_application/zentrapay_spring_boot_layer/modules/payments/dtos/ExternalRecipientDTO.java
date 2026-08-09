package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import jakarta.validation.constraints.NotBlank;

/**
 * External recipient details for payments to other networks (banks, providers):
 * {@code {recipientName, accountNumber, channelCode, bankCode?, bankName?, countryCode?, email?}}
 * <p>
 * Standardized payload structure: recipientDetails, amountDetails, pin
 */
public record ExternalRecipientDTO(
        @NotBlank(message = "Recipient name is required")
        String recipientName,

        @NotBlank(message = "Account number is required")
        String accountNumber,

        @NotBlank(message = "Channel/Bank code is required")
        String channelCode,

        String bankCode,

        String bankName,

        String countryCode,

        String email
) {
}