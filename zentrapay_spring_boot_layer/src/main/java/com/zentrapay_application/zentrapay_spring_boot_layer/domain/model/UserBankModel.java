package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Canonical mapping of {@code linked_funding_sources} (V1__init_schema.sql) —
 * a user's linked bank / mobile-money accounts. Previously this entity pointed
 * at a {@code funding_sources} table that never existed in the Flyway schema
 * and was missing the {@code user_id} column the real table requires.
 */
@Entity
@Data
@Table(name = "user_bank")
public class UserBankModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "user_bank_id", nullable = false)
    private UUID userBankId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "balance", nullable = false)
    private BigDecimal balance;

    @Column(name = "bank_id", nullable = false)
    private UUID bankId;

    @Column(name = "last_digits", nullable = false)
    private String lastDigits;

    @Column(name = "connection_status", nullable = false)
    private String connectionStatus = "active";

    @Column(name = "connection_id", nullable = false)
    private String connectionId;

    @CreationTimestamp
    @Column(name = "linked_at", nullable = false)
    private LocalDateTime linkedAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
