package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto;

import java.util.UUID;

public record AppUserSearchDTO(
        UUID userId,
        String fullName,
        String firstName,
        String lastName,
        String phoneNumber,
        String zentag,
        String userType,
        String email
) {
}
