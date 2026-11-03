package com.zentrapay.backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * A savings goal ("Save Goal" section). {@code savedAmount} is the money the user moved from their
 * wallet account into this goal; each move is also a transaction and a savings-ledger row.
 */
@Entity
@Data
@Table(name = "savings_goals")
public class SavingsGoalModel {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "goal_id", nullable = false, updatable = false)
    private UUID goalId;

    @Column(name = "user_id", nullable = false, updatable = false)
    private UUID userId;

    @Column(name = "goal_name", nullable = false, length = 120)
    private String goalName;

    @Column(name = "currency_code", nullable = false, length = 3, updatable = false)
    private String currencyCode;

    @Column(name = "saved_amount", nullable = false, precision = 19, scale = 4)
    private BigDecimal savedAmount = BigDecimal.ZERO;

    @Column(name = "target_amount", precision = 19, scale = 4)
    private BigDecimal targetAmount;

    @Column(name = "target_date")
    private LocalDate targetDate;

    @Column(name = "description", length = 255)
    private String description;

    // ACTIVE, COMPLETED (target reached), CLOSED
    @Column(name = "status", nullable = false, length = 20)
    private String status = "ACTIVE";

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
