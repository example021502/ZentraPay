package com.zentrapay.backend.entity;

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

    /**
     * Per-user primary marker for the ZBank screen header. At most one row
     * per user may be primary (enforced by the partial unique index
     * {@code uq_user_bank_primary_per_user}); the flag lives here — not on
     * the shared {@code banks} catalog — because "primary" is a property of
     * the user's link, not of the bank itself.
     */
    @Column(name = "is_primary", nullable = false)
    private Boolean primary = false;

    /**
     * User-facing display name chosen in the link sheet (e.g. "Salary").
     * Nullable so older rows keep working; the app falls back to the catalog
     * bank name when absent.
     */
    @Column(name = "link_label", length = 120)
    private String linkLabel;

    @CreationTimestamp
    @Column(name = "linked_at", nullable = false)
    private LocalDateTime linkedAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
