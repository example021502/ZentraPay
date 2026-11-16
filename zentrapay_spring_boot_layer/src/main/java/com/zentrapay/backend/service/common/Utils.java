package com.zentrapay.backend.service.common;

import java.util.Currency;
import java.util.Locale;

public class Utils {

    public static String getZentag(String currencyCode, String phoneNumber) {
        return phoneNumber + "_" + currencyCode + "@zentrapay";
    }
}