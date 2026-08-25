package com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils;

import java.util.Currency;
import java.util.Locale;

public class CurrencyUtil {

    public static String getCurrencyCode(String countryCode) {
        // Pass an empty language and the target country code (e.g., "NG", "GH")
        Locale locale = new Locale("", countryCode.toUpperCase());
        Currency currency = Currency.getInstance(locale);

        return currency != null ? currency.getCurrencyCode() : null;
    }
}