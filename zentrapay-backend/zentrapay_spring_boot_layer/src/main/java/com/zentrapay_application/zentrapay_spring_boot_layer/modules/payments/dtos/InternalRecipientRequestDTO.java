package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import jakarta.validation.constraints.NotBlank;

/**
 * Internal recipient details for wallet-to-wallet transfers.
 * <p>
 * Mirrors the Node.js layer's recipient object for internal payments:
 * <pre>
 * { "phoneNumber": "+2348012345678", "zentag": "@johndoe" }
 * </pre>
 * At least one of {@code phoneNumber} or {@code zentag} must be provided.
 */
public record InternalRecipientRequestDTO(

        String phoneNumber,

        String zentag

) {
}