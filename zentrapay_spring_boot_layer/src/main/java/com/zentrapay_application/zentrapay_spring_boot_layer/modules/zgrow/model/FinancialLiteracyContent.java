package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Canonical mapping of {@code financial_literacy_content} (V1__init_schema.sql),
 * seeded in V3__seed_providers.sql.
 */
@Entity
@Data
@Table(name = "financial_literacy_content")
public class FinancialLiteracyContent {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "content_id", nullable = false)
    private UUID contentId;

    @Column(nullable = false, length = 150)
    private String title;

    @Column(length = 40)
    private String category;

    @Column(name = "content_url", columnDefinition = "TEXT")
    private String contentUrl;

    @Column(name = "duration_minutes")
    private Integer durationMinutes;

    @Column(name = "points_reward", nullable = false)
    private Integer pointsReward = 0;

    @Column(name = "is_active", nullable = false)
    private boolean isActive = true;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
