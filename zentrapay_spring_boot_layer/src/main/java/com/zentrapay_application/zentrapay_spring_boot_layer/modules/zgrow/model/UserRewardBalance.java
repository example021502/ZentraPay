package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Canonical mapping of {@code user_reward_balances} (V1__init_schema.sql) — a
 * transactionally maintained running total; {@code points_ledger} remains the source
 * of truth.
 */
@Entity
@Data
@Table(name = "user_reward_balances")
public class UserRewardBalance {
    @Id
    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "total_points", nullable = false)
    private int totalPoints = 0;

    @Column(nullable = false, length = 20)
    private String tier = "BRONZE"; // BRONZE, SILVER, GOLD, PLATINUM

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
