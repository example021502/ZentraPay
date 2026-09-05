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
@Table(name = "user_challenges")
public class UserChallengesModel {
    @Id
    @Column(name = "id", nullable = false, unique = true)
    private int id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "challenge_id", nullable = false)
    private UUID challengeId;

    @Column(name = "status", nullable = false)
    private String status;

    @CreationTimestamp
    @Column(name = "joined_on", nullable = false)
    private LocalDateTime joinedOn;

    @UpdateTimestamp
    @Column(name = "updated_on", nullable = false)
    private LocalDateTime updatedOn;
}
