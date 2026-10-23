package com.zentrapay.backend.dto.reference;

/**
 * Country row for {@code GET /api/reference/countries} — API_CONTRACT.md §2:
 * {@code {countryCode,iso3Code,countryName,dialCode,defaultCurrencyCode,region}}.
 * Sourced from {@code gateway_countries} (V9 — the canonical supported-countries
 * directory), which replaced the retired world-reference {@code countries} table.
 */
public record CountryDTO(
        String countryCode,
        String iso3Code,
        String countryName,
        String dialCode,
        String defaultCurrencyCode,
        String region
) {
}
