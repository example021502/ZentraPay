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
@Table(name = "user_challenges")
public class JoinedChallenges {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false)
    private UUID Id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "challenge_id", nullable = false)
    private UUID challengeId;

    @UpdateTimestamp
    @Column(name = "joined_at", nullable = false)
    private LocalDateTime joinedAt;
}
