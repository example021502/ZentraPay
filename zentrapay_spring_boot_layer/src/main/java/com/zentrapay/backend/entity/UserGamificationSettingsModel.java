package com.zentrapay.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * One row per user: ZGrow gameplay preferences. `challengesEnabled`
 * decides whether the challenges section is shown and tracked on the
 * client — the app always starts from this persisted value.
 */
@Entity
@Data
@Builder
@Table(name = "user_gamification_settings")
public class UserGamificationSettingsModel {

    @Id
    @Column(name = "user_id", nullable = false, updatable = false)
    private UUID userId;

    @Builder.Default
    @Column(name = "challenges_enabled", nullable = false)
    private boolean challengesEnabled = false;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
