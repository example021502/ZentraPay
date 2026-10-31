package com.zentrapay.backend.dto.wallet;

import com.zentrapay.backend.service.common.Datatypes;

import java.util.UUID;

/**
 * A supported currency entry — maps to the frontend {@code SupportedCurrencies}
 * model ({@code {currencyId,currencyCode,currencyName,countryIsoCode,decimalDigits}}).
 * <p>
 * {@code currencies.currency_code} is both the natural key and the ISO 4217 /
 * crypto-ticker code, so it doubles as {@code currencyId}. {@code countryIsoCode}
 * is best-effort — the first active country whose default currency is this one
 * (a shared currency like XOF maps to several countries; the frontend only uses
 * it to pick a flag icon).
 */
public record SourceDTO(
        UUID sourceId,
        String name,
        Datatypes.PaymentMethod method
) {
}
