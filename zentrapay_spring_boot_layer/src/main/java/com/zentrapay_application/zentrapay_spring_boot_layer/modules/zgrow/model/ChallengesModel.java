package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Canonical mapping of {@code challenges} (V1__init_schema.sql). The previous version
 * of this entity had a {@code participants_count} column that doesn't exist in the
 * table — participant counts are derived via COUNT(*) on user_challenges (see
 * {@link com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.repository.JoinedChallengesRepository}),
 * to avoid a second, staleness-prone source of truth.
 */
@Entity
@Data
@Table(name = "challenges")
public class ChallengeModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "challenge_id", nullable = false)
    private UUID challengeId;

    @Column(name = "category", nullable = false)
    private String category;

    @Column(name = "description", nullable = false)
    private String description;

    @Column(name = "difficulty", nullable = false)
    private String difficulty;

    @Column(name = "points_reward", nullable = false)
    private Integer pointsReward = 0;

    @Column(name = "duration_days", nullable = false)
    private Integer durationDays = 1;

    @Column(name = "status", nullable = false)
    private String status = "active";

    @Column(name = "title", nullable = false)
    private String title;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
}
