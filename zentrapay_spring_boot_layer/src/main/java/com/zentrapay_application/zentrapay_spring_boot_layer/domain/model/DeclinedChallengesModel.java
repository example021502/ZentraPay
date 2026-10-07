package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * A challenge a user explicitly declined. Declining removes any matching
 * {@code user_challenges} row and records the opt-out here instead, so the
 * challenge still appears in that user's "other challenges" list and they can
 * rejoin later. Maps the {@code declined_challenges} table created in V6.
 */
@Entity
@Data
@Table(name = "declined_challenges")
public class DeclinedChallengesModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, unique = true)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "challenge_id", nullable = false)
    private UUID challengeId;

    @CreationTimestamp
    @Column(name = "declined_at")
    private LocalDateTime declinedOn;
}
