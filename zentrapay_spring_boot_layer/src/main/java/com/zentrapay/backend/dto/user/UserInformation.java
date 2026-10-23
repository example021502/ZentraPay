package com.zentrapay.backend.dto.user;

/**
 * {@code GET/PUT /api/users/me/profile} — maps to the {@code user_profiles} table
 * (API contract §1). Nulls until KYC has been submitted.
 */
public record UserInformation(
        UserDTO user,
        UserProfileDTO profile
) {
}
