package com.zentrapay.backend.dto.savings;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.Instant;
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

    /** POST /{goalId}/freeze - stop saving into the goal for 1 to 7 days. */
    public record FreezeRequest(
            @NotNull(message = "Choose how many days to freeze the goal")
            @Min(value = 1, message = "A goal can be frozen for 1 to 7 days")
            @Max(value = 7, message = "A goal can be frozen for at most 7 days")
            Integer days
    ) {
    }

    /** PUT /{goalId}/auto-save - save {amount} into the goal every {frequency} (DAILY, WEEKLY or MONTHLY). */
    public record AutoSaveRequest(
            @NotNull(message = "Amount is required")
            @DecimalMin(value = "0.01", message = "Amount must be greater than zero")
            BigDecimal amount,
            @NotBlank(message = "Choose how often to save")
            String frequency
    ) {
    }

    /** One goal as the app shows it (matches the app's SavingsGoal model). */
    public record GoalDTO(
            UUID savingsId,
            String savingsName,
            String currencyCode,
            BigDecimal balance,
            BigDecimal targetAmount,
            LocalDate targetDate,
            String status,
            String description,
            // Saving is blocked until this moment; null when the goal is not frozen
            Instant frozenUntil,
            boolean autoSaveEnabled,
            BigDecimal autoSaveAmount,
            String autoSaveFrequency,
            Instant autoSaveNextRun,
            Instant createdAt
    ) {
    }

    /** DELETE /{goalId} - what happened to the money that was in the goal. */
    public record DeletedGoalDTO(
            UUID savingsId,
            String savingsName,
            String currencyCode,
            // Moved back to the wallet account when the goal was deleted (0 when it was empty)
            BigDecimal returnedAmount
    ) {
    }

    /** One row of "recent saving activity": a deposit / withdrawal / automatic save, including refused ones. */
    public record ActivityDTO(
            UUID activityId,
            UUID savingsId,
            String savingsName,
            // DEPOSIT or WITHDRAWAL
            String type,
            // true when it was an automatic (scheduled) save
            boolean auto,
            BigDecimal amount,
            String currencyCode,
            // SUCCESS, FAILED ...
            String status,
            String failureReason,
            Instant createdAt
    ) {
    }
}
