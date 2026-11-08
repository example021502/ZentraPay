package com.zentrapay.backend.dto.provider;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;
import java.util.UUID;

/**
 * The services a user added to their Home screen ({@code /api/user-services}).
 *
 * @param kind BILL (a bill provider, payable) or SERVICE (a service provider)
 */
public record UserServiceDTO(
        UUID userServiceId,
        String kind,
        UUID providerId,
        String name,
        String logoUrl,
        String categoryCode,
        String countryCode,
        Instant addedAt
) {

    /** POST /api/user-services body. */
    public record AddRequest(
            @NotBlank(message = "Kind is required (BILL or SERVICE)") String kind,
            @NotNull(message = "Provider is required") UUID providerId
    ) {
    }
}
