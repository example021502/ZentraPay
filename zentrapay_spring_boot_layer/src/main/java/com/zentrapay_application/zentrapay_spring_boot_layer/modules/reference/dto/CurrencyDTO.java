package com.zentrapay_application.zentrapay_spring_boot_layer.modules.reference.dto;

/**
 * Currency row for {@code GET /api/reference/currencies} — API_CONTRACT.md §2:
 * {@code {currencyCode,currencyName,symbol,isCrypto,decimalPlaces}}.
 */
public record CurrencyDTO(
        String currencyCode,
        String currencyName,
        String symbol,
        boolean isCrypto,
        short decimalPlaces
) {
}
