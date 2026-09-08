package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * The single canonical mapping of the "users" table. Every module that
 * needs a user (payments, search, transactions, ...) reads/writes this
 * entity — no module should declare its own parallel @Entity for "users".
 */
@Entity
@Data
@Table(name = "challenges")
public class ChallengesModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "challenge_id", nullable = false, unique = true)
    private UUID challengeId;

    @Column(name = "category", nullable = false)
    private String category;

    @Column(name = "description", nullable = false)
    private String description;

    @Column(name = "difficult", nullable = false)
    private String difficult;

    @Column(name = "duration_days", nullable = false)
    private int durationDays;

    @Column(name = "points_reward", nullable = false)
    private int pointsReward;

    @Column(name = "status", nullable = false)
    private String status;

    @Column(name = "title", nullable = false)
    private String title;

    @CreationTimestamp
    @Column(name = "created_on", nullable = false)
    private LocalDateTime createdOn;

    @UpdateTimestamp
    @Column(name = "updated_on", nullable = false)
    private LocalDateTime updatedOn;
}
