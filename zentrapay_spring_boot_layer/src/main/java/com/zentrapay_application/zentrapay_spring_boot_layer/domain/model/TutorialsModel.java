package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.Datatypes;
import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Entity representing company-wide rewards available in the catalog.
 */
@Entity
@Data
@Table(name = "tutorials")
public class TutorialsModel {

    // Primary Key mapped to reward_id UUID
    @Id
    @Column(name = "id", nullable = false, unique = true, updatable = false)
    private int id;

    // Display title/name of the reward
    @Column(name = "title", nullable = false)
    private String title;

    // Custom PostgreSQL Enum mapped as String in JPA
    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false)
    private Datatypes.TutorialTypeEnum type;

    // Display title/name of the reward
    @Column(name = "description", nullable = false)
    private String description;

    // Quantitative value or worth (e.g., points, cash value)
    @Column(name = "video_url", nullable = false)
    private String videoUrl;

    // Display title/name of the reward
    @Column(name = "thumbnail_url", nullable = false)
    private String thumbnailUrl;

    // Display title/name of the reward
    @Column(name = "duration_seconds", nullable = false)
    private int durationSeconds;

    // Soft-delete / status flag
    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    // Automatic creation timestamp
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // Automatic update timestamp
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}