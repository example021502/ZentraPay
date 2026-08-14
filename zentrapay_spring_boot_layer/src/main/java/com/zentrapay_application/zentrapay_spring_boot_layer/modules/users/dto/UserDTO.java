package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto;

import java.util.UUID;

/**
 * Response shape for {@code GET/PATCH /api/users/me} (API contract §1):
 * {@code {userId,firstName,lastName,email,phoneNumber,countryCode,zentag,userType,status,kycTier}}.
 */
public record UserDTO(
        UUID userId,
        String firstName,
        String lastName,
        String fullName,
        String email,
        String phoneNumber,
        String zentag,
        String passwordHash
) {
}
