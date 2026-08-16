package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Canonical mapping of {@code linked_funding_sources} (V1__init_schema.sql) —
 * a user's linked bank / mobile-money accounts. Previously this entity pointed
 * at a {@code funding_sources} table that never existed in the Flyway schema
 * and was missing the {@code user_id} column the real table requires.
 */
@Entity
@Data
@Table(name = "user_funding_sources")
public class UserFundingSourceModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "user_funding_source_id", nullable = false)
    private UUID userFundingSourceId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "source_id", nullable = false)
    private UUID sourceId;

    @Column(name = "is_primary", nullable = false)
    private Boolean isPrimary;

    @CreationTimestamp
    @Column(name = "linked_at", nullable = false)
    private LocalDateTime linkedAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
