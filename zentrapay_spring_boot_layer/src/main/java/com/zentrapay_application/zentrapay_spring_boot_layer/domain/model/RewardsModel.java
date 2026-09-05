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
@Table(name = "rewards")
public class RewardsModel {

    // Primary Key mapped to reward_id UUID
    @Id
    @Column(name = "reward_id", nullable = false, unique = true, updatable = false)
    private int rewardId;

    // Custom PostgreSQL Enum mapped as String in JPA
    @Enumerated(EnumType.STRING)
    @Column(name = "reward_type", nullable = false)
    private Datatypes.RewardTypeEnum rewardType;

    // Display title/name of the reward
    @Column(name = "title", nullable = false)
    private String title;

    // Display title/name of the reward
    @Column(name = "description", nullable = false)
    private String description;

    // Quantitative value or worth (e.g., points, cash value)
    @Column(name = "worth", nullable = false, precision = 10, scale = 2)
    private BigDecimal worth;

    // Display title/name of the reward
    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    // Soft-delete / status flag
    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    // Automatic creation timestamp
    @CreationTimestamp
    @Column(name = "created_on", nullable = false, updatable = false)
    private LocalDateTime createdOn;

    // Automatic update timestamp
    @UpdateTimestamp
    @Column(name = "updated_on", nullable = false)
    private LocalDateTime updatedOn;
}