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
@Table(name = "funding_sources")
public class LinkedFundingSource {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "source_id", nullable = false)
    private UUID sourceId;

    @Column(name = "account_identifier", nullable = false)
    private String accountIdentifier;

    @Column(name = "channel_code", nullable = false)
    private String channelCode;

    @Column(name = "country_code", nullable = false)
    private String countryCode;

    @Column(name = "is_verified", nullable = false)
    private Boolean isVerified;

    @Column(name = "source_name", nullable = false)
    private String sourceName;

    @Column(name = "source_type", nullable = false)
    private String sourceType;

    @Column(name = "account_name", nullable = false)
    private String accountName;

    @Column(name = "funding_source_code", nullable = false)
    private String fundingSourceCode;

    @Column(name = "currency", nullable = false)
    private String currency;

    @Column(name = "funding_type", nullable = false)
    private String fundingType;

    @Column(name = "is_primary", nullable = false)
    private Boolean isPrimary;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
