package com.zentrapay.backend.entity;

import com.zentrapay.backend.service.common.Datatypes;
import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Entity representing company-wide rewards available in the catalog.
 */
@Entity
@Data
@Table(name = "funding_sources")
public class SourcesModel {

    // Primary Key mapped to reward_id UUID
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "source_id", nullable = false, unique = true, updatable = false)
    private UUID sourceId;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "payment_method", nullable = false)
    private Datatypes.PaymentMethod method;

    // Soft-delete / status flag
    @Column(name = "active", nullable = false)
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