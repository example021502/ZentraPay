package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

/**
 * {@code POST /api/payments/internal} recipient shape (API contract §6):
 * {@code {phoneNumber?,zentag?}} — at least one must be provided.
 */
public record InternalRecipientDTO(
        String phoneNumber,
        String zentag
) {
}
