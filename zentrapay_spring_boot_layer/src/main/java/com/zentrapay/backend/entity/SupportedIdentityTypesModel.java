package com.zentrapay.backend.entity;

import com.zentrapay.backend.service.common.Datatypes;
import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Entity representing company-wide rewards available in the catalog.
 */
@Entity
@Data
@Table(name = "supported_identity_types")
public class SupportedIdentityTypesModel {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    @Column(name = "id", nullable = false, unique = true, updatable = false)
    private int id;

    @Column(name = "country", nullable = false)
    private String countryCode;

    @Column(name = "currency", nullable = false)
    private String currency;

    @Column(name = "identity_type_key", nullable = false)
    private String identityTypeKey;

    @Column(name = "identity_type_name", nullable = false)
    private String identityTypeName;

    @Column(name = "is_active", nullable = false)
    private boolean isActive;

    @Column(name = "regex_pattern", nullable = false)
    private String regexPattern;

    // Automatic creation timestamp
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // Automatic update timestamp
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}