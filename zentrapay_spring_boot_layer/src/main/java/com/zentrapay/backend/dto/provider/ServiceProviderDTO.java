package com.zentrapay.backend.dto.provider;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Service-provider row for {@code GET /api/service-providers} — API_CONTRACT.md §9:
 * {@code {providerId,providerName,categoryCode,logoUrl,minAmount,maxAmount,countryCode}}.
 * {@code countryCode} lets the client render the corridor's flag when the
 * provider has no logo (same convention as the bill-provider directory).
 */
public record ServiceProviderDTO(
        UUID providerId,
        String providerName,
        String categoryCode,
        String logoUrl,
        BigDecimal minAmount,
        BigDecimal maxAmount,
        String countryCode
) {
}
