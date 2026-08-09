package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Canonical mapping of {@code challenge_participants} (V1__init_schema.sql).
 */
@Entity
@Data
@Table(name = "challenge_participants")
public class ChallengeParticipant {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "participant_id", nullable = false)
    private UUID participantId;

    @Column(name = "challenge_id", nullable = false)
    private UUID challengeId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @CreationTimestamp
    @Column(name = "joined_at", nullable = false)
    private LocalDateTime joinedAt;

    @Column(name = "progress_percent", nullable = false)
    private short progressPercent = 0;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Column(name = "points_earned", nullable = false)
    private int pointsEarned = 0;
}
