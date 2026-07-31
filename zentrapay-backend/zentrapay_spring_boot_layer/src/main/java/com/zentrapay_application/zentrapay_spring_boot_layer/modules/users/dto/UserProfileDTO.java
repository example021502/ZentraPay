package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto;

import java.util.UUID;

public record UserProfileDTO(
        UUID userId,
        String email,
        String fullName,
        String zentag,
        String phoneNumber,
        String country,
        String status
) {
}
