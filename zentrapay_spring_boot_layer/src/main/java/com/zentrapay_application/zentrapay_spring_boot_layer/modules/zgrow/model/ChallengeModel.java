package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Canonical mapping of {@code challenges} (V1__init_schema.sql). The previous version
 * of this entity had a {@code participants_count} column that doesn't exist in the
 * table — participant counts are derived via COUNT(*) on challenge_participants (see
 * {@link com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.repository.ChallengeParticipantRepository}),
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

    @Column(nullable = false, length = 120)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(length = 40)
    private String category; // SAVINGS, SPENDING, INVESTING

    @Column(name = "duration_days", nullable = false)
    private Integer durationDays;

    @Column(name = "points_reward", nullable = false)
    private Integer pointsReward = 0;

    @Column(length = 20)
    private String difficulty; // EASY, MEDIUM, HARD

    @Column(nullable = false, length = 20)
    private String status = "ACTIVE"; // ACTIVE, ARCHIVED

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
