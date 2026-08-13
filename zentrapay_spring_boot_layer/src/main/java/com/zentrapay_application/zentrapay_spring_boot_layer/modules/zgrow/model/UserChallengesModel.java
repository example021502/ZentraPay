package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Canonical mapping of {@code user_challenges} (V6__zgrow_user_challenges.sql) —
 * a challenge a specific user has joined/accepted, with their own progress on
 * it. Private per user: joining challenge X never surfaces which other users
 * also joined it, only an aggregate {@code COUNT(*)} (see
 * {@link com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.repository.JoinedChallengesRepository#countByChallengeId}).
 * Mirrored by {@link DeclinedChallenges} for the challenges this user turned down.
 */
@Entity
@Data
@Table(name = "user_challenges")
public class UserChallengesModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "user_challenge_id", nullable = false)
    private UUID userChallengeId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "challenge_id", nullable = false)
    private UUID challengeId;

//    @Column(name = "progress_percent", nullable = false)
//    private short progressPercent = 0;

//    @Column(name = "completed_at")
//    private LocalDateTime completedAt;

//    @Column(name = "points_earned", nullable = false)
//    private int pointsEarned = 0;

    @CreationTimestamp
    @Column(name = "joined_at", nullable = false)
    private LocalDateTime joinedAt;

    @CreationTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
