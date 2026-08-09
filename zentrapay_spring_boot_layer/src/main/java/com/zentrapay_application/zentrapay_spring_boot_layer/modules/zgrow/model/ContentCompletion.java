package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Canonical mapping of {@code content_completions} (V1__init_schema.sql). Unique
 * constraint on (content_id, user_id) makes completion idempotent per API_CONTRACT.md §14.
 */
@Entity
@Data
@Table(name = "content_completions")
public class ContentCompletion {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "completion_id", nullable = false)
    private UUID completionId;

    @Column(name = "content_id", nullable = false)
    private UUID contentId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @CreationTimestamp
    @Column(name = "completed_at", nullable = false)
    private LocalDateTime completedAt;

    @Column(name = "points_earned", nullable = false)
    private int pointsEarned = 0;
}
