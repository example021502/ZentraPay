package com.zentrapay.backend.dto.search;

import java.util.UUID;

/** A mobile-money network surfaced by contact search (for sending to a wallet on that network). */
public record MobileMoneySearchDTO(
        UUID providerId,
        String name,
        String providerCode,
        String countryCode
) {
}
