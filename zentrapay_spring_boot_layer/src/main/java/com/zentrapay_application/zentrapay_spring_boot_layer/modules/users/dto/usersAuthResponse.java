package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto;

import java.util.UUID;

/**
 * DTO representing the data returned upon successful authentication
 * (register/login/refresh). Field order/names match §1 of the API contract:
 * {@code {token,userId,email,fullName,zentag}}.
 */
public record usersAuthResponse(
        String token,
        UUID userId,
        String email,
        String fullName,
        String zentag
) {
}
