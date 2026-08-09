package com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittance.dtos;

import jakarta.validation.constraints.NotBlank;

import java.util.UUID;

/**
 * Recipient details for remittance requests.
 * Part of the standardized payload structure: recipientDetails, amountDetails, pin
 */
public record RemittanceRecipientDTO(
        @NotBlank(message = "Recipient name is required")
        String recipientName,

        @NotBlank(message = "Recipient phone number is required")
        String recipientPhoneNumber,

        UUID recipientUserId,

        @NotBlank(message = "Recipient country code is required")
        String recipientCountryCode
) {
}