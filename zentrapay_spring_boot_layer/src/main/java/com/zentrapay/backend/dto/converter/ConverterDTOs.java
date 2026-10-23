package com.zentrapay.backend.dto.converter;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Map;

/**
 * Request / response shapes of the converter endpoints (/api/converter/*).
 */
public final class ConverterDTOs {

    private ConverterDTOs() {
    }

    /** GET /rates - maps each currency code to the rate from {@code base}. */
    public record RatesDTO(String base, Map<String, String> rates) {
    }

    /** POST /convert body. */
    public record ConvertRequestDTO(
            @NotBlank(message = "From currency is required") String from,
            @NotBlank(message = "To currency is required") String to,
            @NotNull(message = "Amount is required")
            @DecimalMin(value = "0.01", message = "Amount must be greater than zero") BigDecimal amount
    ) {
    }

    /** POST /convert response. */
    public record ConvertResponseDTO(BigDecimal convertedAmount, BigDecimal rate) {
    }

    /** One row of GET /history. */
    public record ConversionHistoryDTO(String fromCurrency, String toCurrency, BigDecimal amount,
                                       BigDecimal convertedAmount, LocalDateTime createdAt) {
    }
}
