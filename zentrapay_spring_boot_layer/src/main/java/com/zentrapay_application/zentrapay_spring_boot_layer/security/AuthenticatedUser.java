package com.zentrapay_application.zentrapay_spring_boot_layer.security;

import java.security.Principal;
import java.util.UUID;

/**
 * Identity resolved from a validated JWT's claims, set as the Authentication principal
 * by {@link JwtAuthenticationFilter} for every request except register/login.
 * <p>
 * Implements {@link Principal#getName()} as {@code userId.toString()} so that existing
 * {@code UUID.fromString(authentication.getName())} call sites keep working unchanged.
 */
public record AuthenticatedUser(
        UUID userId,
        String email,
        String fullName,
        String zentag
) implements Principal {

    @Override
    public String getName() {
        return fullName;
    }

    public UUID getUserId() {
        return userId;
    }

    public String getEmail() {
        return email;
    }

    public String getZentag() {
        return zentag;
    }

}
