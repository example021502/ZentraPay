package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto;

/**
 * {@code GET/PUT /api/users/me/profile} — maps to the {@code user_profiles} table
 * (API contract §1). Nulls until KYC has been submitted.
 */
public record UserInformation(
        UserDTO user,
        UserProfileDTO profile
) {
}
