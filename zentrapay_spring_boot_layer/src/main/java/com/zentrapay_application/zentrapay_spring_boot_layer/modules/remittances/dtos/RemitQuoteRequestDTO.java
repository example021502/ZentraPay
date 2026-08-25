package com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittances.dtos;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

/**
 * POST /api/remit/quote body — pre-flight FX preview for the ZRemit form.
 * The destination currency is derived from {@code destinationCountryCode}
 * (the country's default gateway-supported currency), so the caller never
 * has to guess it.
 */
public record RemitQuoteRequestDTO(
        @NotNull(message = "Amount is required")
        @DecimalMin(value = "0.01", message = "Amount must be greater than zero")
        BigDecimal amount,

        @NotBlank(message = "Source currency code is required")
        String sourceCurrencyCode,

        @NotBlank(message = "Destination country is required")
        String destinationCountryCode
) {
}