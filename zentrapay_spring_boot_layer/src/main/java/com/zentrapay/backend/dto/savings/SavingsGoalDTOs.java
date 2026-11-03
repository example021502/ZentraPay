package com.zentrapay.backend.dto.savings;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Request / response shapes of the savings goal endpoints (/api/zbanking/savings/*).
 */
public final class SavingsGoalDTOs {

    private SavingsGoalDTOs() {
    }

    /** POST /api/zbanking/savings - a new goal, optionally funded straight away from the wallet. */
    public record CreateGoalRequest(
            @NotBlank(message = "Give your goal a name")
            String savingsName,
            @NotBlank(message = "Currency code is required")
            String currencyCode,
            // Moved from the wallet account in the goal's currency; 0 / empty = create the goal empty
            BigDecimal initialDeposit,
            BigDecimal targetAmount,
            LocalDate targetDate,
            String description
    ) {
    }

    /** POST /{goalId}/deposit and /{goalId}/withdraw */
    public record AmountRequest(
            @NotNull(message = "Amount is required")
            @DecimalMin(value = "0.01", message = "Amount must be greater than zero")
            BigDecimal amount
    ) {
    }

    /** One goal as the app shows it (matches the app's SavingsAccount model). */
    public record GoalDTO(
            UUID savingsId,
            String savingsName,
            String currencyCode,
            BigDecimal balance,
            BigDecimal targetAmount,
            LocalDate targetDate,
            String status,
            String description
    ) {
    }
}
