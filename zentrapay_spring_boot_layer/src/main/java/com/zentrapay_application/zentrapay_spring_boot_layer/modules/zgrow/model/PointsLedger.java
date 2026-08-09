package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Canonical mapping of {@code points_ledger} (V1__init_schema.sql) — append-only
 * ledger of every point award; {@code user_reward_balances} is a running total kept
 * only so reads don't need to SUM() the whole ledger, this table remains the source
 * of truth.
 */
@Entity
@Data
@Table(name = "points_ledger")
public class PointsLedger {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "ledger_id", nullable = false)
    private UUID ledgerId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(nullable = false)
    private int points;

    @Column(nullable = false, length = 60)
    private String reason;

    @Column(name = "reference_type", length = 30)
    private String referenceType; // CHALLENGE, LITERACY_CONTENT, REFERRAL...

    @Column(name = "reference_id")
    private UUID referenceId;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
}
