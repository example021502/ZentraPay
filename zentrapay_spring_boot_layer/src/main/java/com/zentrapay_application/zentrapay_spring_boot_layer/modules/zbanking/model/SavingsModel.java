package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Canonical mapping of {@code savings_accounts} (V1__init_schema.sql). Fixed to match
 * the table exactly — the previous version mapped {@code currency} to a nonexistent
 * "currency" column (the table's column is currency_code) and had no wallet_id, which
 * this module needs to know which wallet to debit/credit on deposit/withdraw.
 */
@Entity
@Data
@Table(name = "savings_accounts")
public class SavingsModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "savings_id", nullable = false)
    private UUID savingsId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "wallet_id")
    private UUID walletId;

    @Column(name = "savings_name", nullable = false, length = 80)
    private String savingsName;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @Column(nullable = false, precision = 19, scale = 4)
    private BigDecimal balance = BigDecimal.ZERO;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "target_date")
    private LocalDate targetDate;

    @Column(name = "target_amount", precision = 19, scale = 4)
    private BigDecimal targetAmount;

    @Column(nullable = false, length = 20)
    private String status = "ACTIVE";

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
