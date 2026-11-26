// Always add inline comments for code readability and maintenance
package com.zentrapay.backend.entity;

import com.zentrapay.backend.service.common.Datatypes;
import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

// Stores a user's configured spending limit for a specific time period and currency.
@Entity
@Data
@Table(
        name = "user_budgets",
        uniqueConstraints = {
                // Allows a user to maintain distinct limits per currency and budget period (e.g., daily and monthly).
                @UniqueConstraint(
                        name = "uk_user_budgets_user_currency_period",
                        columnNames = {"user_id", "currency_code", "budget_period"}
                )
        },
        indexes = {
                // Speeds up loading all budget rules configured for a user.
                @Index(
                        name = "idx_user_budgets_user_id",
                        columnList = "user_id"
                )
        }
)
public class UserBudgetModel {
    // Primary identifier for the user budget record.
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    // Owner user ID to whom this spending limit applies.
    @Column(name = "user_id", nullable = false, updatable = false)
    private UUID userId;

    // Maximum allowed to be spent amount for the configured period (named spending_limit to avoid SQL LIMIT keyword collisions).
    @Column(name = "limit", nullable = false, precision = 19, scale = 4)
    private BigDecimal limit;

    // Time window over which the spending limit is evaluated (e.g., DAILY, MONTHLY, YEARLY).
    @Enumerated(EnumType.STRING)
    @Column(name = "period", nullable = false, length = 20)
    private Datatypes.BudgetPeriod period = Datatypes.BudgetPeriod.MONTHLY;

    // ISO 4217 currency code for this spending limit (e.g., KES, NGN, GHS).
    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    // Optimistic lock version to prevent concurrent update conflicts.
    @Version
    @Column(name = "version", nullable = false)
    private Long version;

    // Timestamp when the budget limit was created.
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // Timestamp automatically updated when the spending limit or period changes.
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}