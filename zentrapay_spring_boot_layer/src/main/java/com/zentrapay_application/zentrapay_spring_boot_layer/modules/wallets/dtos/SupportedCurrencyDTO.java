package com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.dtos;

/**
 * A supported currency entry — maps to the frontend {@code SupportedCurrencies}
 * model ({@code {currencyId,currencyCode,currencyName,countryIsoCode,decimalDigits}}).
 *
 * {@code currencies.currency_code} is both the natural key and the ISO 4217 /
 * crypto-ticker code, so it doubles as {@code currencyId}. {@code countryIsoCode}
 * is best-effort — the first active country whose default currency is this one
 * (a shared currency like XOF maps to several countries; the frontend only uses
 * it to pick a flag icon).
 */
public record SupportedCurrencyDTO(
        String currencyCode,
        String currencyName,
        int decimalDigits
) {
}
