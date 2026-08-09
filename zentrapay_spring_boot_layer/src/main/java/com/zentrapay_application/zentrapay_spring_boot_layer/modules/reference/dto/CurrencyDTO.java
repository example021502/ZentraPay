package com.zentrapay_application.zentrapay_spring_boot_layer.modules.reference.dto;

public record CurrencyDTO(
        String currencyCode,
        String currencyName,
        String symbol,
        boolean isCrypto,
        short decimalPlaces
) {
}
