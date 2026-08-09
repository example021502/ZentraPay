package com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittance.dtos;

import jakarta.validation.constraints.NotBlank;

/**
 * Recipient details for remittance payments (API contract §12):
 * {@code {recipientName, recipientPhoneNumber, recipientUserId?, recipientCountryCode}}
 */
public record RecipientDetailsDTO(
        @NotBlank(message = "Recipient name is required")
        String recipientName,

        String recipientPhoneNumber,

        String recipientUserId,

        @NotBlank(message = "Recipient country code is required")
        String recipientCountryCode
) {
}