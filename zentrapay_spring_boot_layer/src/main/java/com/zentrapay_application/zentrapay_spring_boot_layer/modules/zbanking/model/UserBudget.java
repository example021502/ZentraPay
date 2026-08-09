package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Canonical mapping of {@code user_budgets} (V4__additional_tables.sql).
 */
@Entity
@Data
@Table(name = "user_budgets")
public class UserBudget {
    @Id
    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "monthly_limit", nullable = false, precision = 19, scale = 4)
    private BigDecimal monthlyLimit;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
