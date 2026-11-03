package com.zentrapay.backend.dto.reference;

import java.util.List;

/**
 * Currency row for {@code GET /api/reference/currencies} - API_CONTRACT.md §2:
 * {@code {currencyCode,currencyName,symbol,isCrypto,decimalPlaces,countryCodes}}.
 *
 * <p>There is no currencies table: a currency appears here because at least one active country has it as
 * its {@code default_currency}, and {@code countryCodes} lists those countries (XOF is shared by several).
 */
public record CurrencyDTO(
        String currencyCode,
        String currencyName,
        String symbol,
        boolean isCrypto,
        short decimalPlaces,
        List<String> countryCodes
) {
}
