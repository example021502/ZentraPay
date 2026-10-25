package com.zentrapay.backend.dto.user;

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
        String firstName,
        String lastName
) {
}
