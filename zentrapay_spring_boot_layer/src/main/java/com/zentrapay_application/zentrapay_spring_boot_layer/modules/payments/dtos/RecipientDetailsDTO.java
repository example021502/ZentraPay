package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;
/**
 * {@code POST /api/payments/internal} recipient shape (API contract §6):
 * {@code {phoneNumber?,zentag?}} — at least one must be provided.
 */
public record RecipientDetailsDTO(
        String phoneNumber,
        String zentag,
        String email,
        String firstName,
        String lastName,
        String fullName,
        String identifier,
        String recipientType
) {
}
