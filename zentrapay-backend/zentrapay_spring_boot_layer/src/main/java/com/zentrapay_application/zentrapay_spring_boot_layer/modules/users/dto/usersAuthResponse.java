package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto;

import java.util.UUID;

/**
 * DTO representing the data returned upon successful authentication.
 * We use a Java record here for immutability and conciseness.
 */
public record usersAuthResponse(
        UUID userId,
        String email
) {
}
