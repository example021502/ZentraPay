package com.zentrapay.backend.dto.invest;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Request / response shapes of the ZInvest endpoints (/api/zinvest/*).
 */
public final class InvestmentDTOs {

    private InvestmentDTOs() {
    }

    /** POST /api/zinvest/invest - open a position; quantity x buyPrice is taken from the wallet. */
    public record InvestRequest(
            @NotBlank(message = "Give the investment a name")
            String name,
            @NotBlank(message = "Investment type is required")
            String investmentType,
            String symbol,
            @NotNull(message = "Quantity is required")
            @DecimalMin(value = "0.0001", message = "Quantity must be greater than zero")
            BigDecimal quantity,
            @NotNull(message = "Buy price is required")
            @DecimalMin(value = "0.0001", message = "Buy price must be greater than zero")
            BigDecimal buyPrice,
            @NotBlank(message = "Currency code is required")
            String currencyCode
    ) {
    }

    /** One position as the app shows it (matches the app's Investment model). */
    public record InvestmentDTO(
            UUID investmentId,
            String name,
            String investmentType,
            String symbol,
            BigDecimal quantity,
            BigDecimal buyPrice,
            BigDecimal currentPrice,
            String currencyCode,
            String status
    ) {
    }
}
