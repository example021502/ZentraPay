package com.zentrapay.backend.service.region;

import java.util.Locale;
import java.util.Map;

/**
 * Display facts about a currency code - name, symbol and decimal places.
 *
 * <p>There is no currencies table any more: WHICH currencies are usable comes from the countries'
 * {@code default_currency} column, and this class only describes a code for the screens (a symbol like
 * "GH₵" is not something the JDK knows). Unknown codes fall back to the JDK's own data, then to the code itself.
 */
public final class CurrencyCatalog {

    // Symbols the JDK does not give us (it would answer with the bare code)
    private static final Map<String, String> SYMBOLS = Map.ofEntries(
            Map.entry("GHS", "GH₵"), Map.entry("NGN", "₦"), Map.entry("KES", "KSh"),
            Map.entry("TZS", "TSh"), Map.entry("UGX", "USh"), Map.entry("RWF", "FRw"),
            Map.entry("ZAR", "R"), Map.entry("XOF", "CFA"), Map.entry("XAF", "FCFA"),
            Map.entry("ETB", "Br"), Map.entry("EGP", "E£"), Map.entry("MAD", "MAD"),
            Map.entry("ZMW", "ZK"), Map.entry("BWP", "P"), Map.entry("MZN", "MT"),
            Map.entry("AOA", "Kz"), Map.entry("SLL", "Le"), Map.entry("USD", "$"),
            Map.entry("EUR", "€"), Map.entry("GBP", "£"));

    // Names the JDK words differently from what the app shows
    private static final Map<String, String> NAMES = Map.of(
            "GHS", "Ghanaian Cedi", "XOF", "West African CFA Franc", "XAF", "Central African CFA Franc");

    private CurrencyCatalog() {
    }

    public static String name(String code) {
        String key = normalise(code);
        String named = NAMES.get(key);
        if (named != null) {
            return named;
        }
        return jdk(key) == null ? key : jdk(key).getDisplayName(Locale.ENGLISH);
    }

    public static String symbol(String code) {
        String key = normalise(code);
        return SYMBOLS.getOrDefault(key, key);
    }

    public static short decimals(String code) {
        java.util.Currency currency = jdk(normalise(code));
        int digits = currency == null ? 2 : currency.getDefaultFractionDigits();
        return (short) (digits < 0 ? 2 : digits);
    }

    private static String normalise(String code) {
        return code == null ? "" : code.trim().toUpperCase(Locale.ROOT);
    }

    private static java.util.Currency jdk(String code) {
        try {
            return java.util.Currency.getInstance(code);
        } catch (IllegalArgumentException unknown) {
            return null;
        }
    }
}
