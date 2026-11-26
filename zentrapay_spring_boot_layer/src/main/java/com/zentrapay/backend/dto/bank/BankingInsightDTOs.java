package com.zentrapay.backend.dto.bank;

import com.zentrapay.backend.service.common.Datatypes;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.util.List;

/**
 * Shapes of GET /api/zbanking/insights and GET/PUT /api/zbanking/budget (match the app's
 * BankingInsights / BudgetSummary models).
 */
public final class BankingInsightDTOs {

    private BankingInsightDTOs() {
    }

    /**
     * Where the month's spending went: a category code and the amount.
     */
    public record SpendCategoryDTO(String categoryCode, BigDecimal amount) {
    }

    /**
     * This calendar month, in the user's home currency.
     */
    public record InsightsDTO(BigDecimal spend, BigDecimal income, Datatypes.BudgetPeriod period,
                              List<SpendCategoryDTO> topCategories) {
    }

    /**
     * PUT /api/zbanking/budget
     */
    public record SetBudgetRequest(
            @NotNull(message = "Monthly limit is required")
            @DecimalMin(value = "0.00", message = "The limit cannot be negative")
            BigDecimal limit,

            @NotBlank(message = "Currency type missing.")
            String currencyCode,

            @NotNull(message = "Period missing.") Datatypes.BudgetPeriod period
    ) {
    }

    /**
     * The limit, what has been spent this month and what is left (never below zero).
     */
    public record BudgetDTO(String currencyCode, BigDecimal limit, BigDecimal spend,
                            BigDecimal remaining, Datatypes.BudgetPeriod period) {
    }
}
