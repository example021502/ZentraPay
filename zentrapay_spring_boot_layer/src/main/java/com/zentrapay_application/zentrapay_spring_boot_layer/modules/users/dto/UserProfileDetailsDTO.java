package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto;

import java.time.LocalDate;

/**
 * {@code GET/PUT /api/users/me/profile} — maps to the {@code user_profiles} table
 * (API contract §1). Nulls until KYC has been submitted.
 */
public record UserProfileDetailsDTO(
        LocalDate dateOfBirth,
        String idDocumentType,
        String idDocumentNumber,
        String idDocumentCountryCode,
        String addressLine1,
        String addressLine2,
        String city,
        String regionState,
        String postalCode,
        String occupation,
        String amlStatus,
        boolean isPep
) {
}
