package com.zentrapay.backend.entity;

import com.zentrapay.backend.service.common.Datatypes;
import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

// Represents a user-created savings goal; actual fund movements are recorded in transactions and the savings ledger.
@Entity
@Data
@Table(
        name = "goals",
        indexes = {
                // Speeds up loading a user's goals filtered by status (e.g., ACTIVE, COMPLETED, CLOSED).
                @Index(
                        name = "idx_goals_user_status",
                        columnList = "user_id, status"
                ),
                // Speeds up scheduled auto-save queries for due recurring transfers.
                @Index(
                        name = "idx_goals_auto_schedule",
                        columnList = "auto_enabled, status, auto_next_run"
                )
        }
)
public class SavingsGoalModel {

    // Primary identifier for the savings goal.
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    // Owner user ID who created and manages the goal.
    @Column(name = "user_id", nullable = false, updatable = false)
    private UUID userId;

    // User-facing goal title (e.g., "Emergency Fund", "December Trip").
    @Column(name = "name", nullable = false, length = 120)
    private String name;

    // ISO currency code for the goal balance and target (e.g., KES, NGN, GHS).
    @Column(name = "currency_code", nullable = false, length = 3, updatable = false)
    private String currencyCode;

    // Current accumulated balance transferred into this goal.
    @Column(name = "saved_amount", nullable = false, precision = 19, scale = 4)
    private BigDecimal savedAmount = BigDecimal.ZERO;

    // Optional target amount the user aims to save.
    @Column(name = "target_amount", precision = 19, scale = 4)
    private BigDecimal targetAmount;

    // Optional target completion date for pacing/progress display.
    @Column(name = "target_date")
    private LocalDate targetDate;

    // Optional notes or purpose for the goal.
    @Column(name = "description", length = 255)
    private String description;

    // Lifecycle state of the goal (ACTIVE, COMPLETED, CLOSED).
    @Column(name = "status", nullable = false, length = 20)
    private String status = "ACTIVE";

    // Blocks deposits into the goal until this timestamp (null or past means unfrozen).
    @Column(name = "frozen_until")
    private LocalDateTime frozenUntil;

    // Whether automated recurring transfers from the user's wallet into this goal are enabled.
    @Column(name = "auto_enabled", nullable = false)
    private boolean autoEnabled = false;

    // Fixed amount moved automatically per auto-save run.
    @Column(name = "auto_amount", precision = 19, scale = 4)
    private BigDecimal autoAmount;

    // Recurrence cadence for auto-save (DAILY, WEEKLY, MONTHLY).
    @Column(name = "auto_frequency")
    private Datatypes.AutoSaveFrequency autoFrequency = Datatypes.AutoSaveFrequency.DAILY;

    // Next scheduled timestamp when the auto-save job should attempt a transfer.
    @Column(name = "auto_next_run")
    private LocalDateTime autoNextRun;

    // Optimistic locking version to prevent race conditions during concurrent balance/schedule updates.
    @Version
    @Column(name = "version", nullable = false)
    private Long version;

    // Timestamp when the goal was created.
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // Timestamp automatically updated when goal details, balance, or settings change.
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}