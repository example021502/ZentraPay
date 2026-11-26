package com.zentrapay.backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

// Catalog of supported KYC/identity document types and format rules per country and currency.
@Entity
@Data
@Table(
        name = "supported_identity_types",
        uniqueConstraints = {
                // Ensures only one rule exists per identity type key within a country and currency.
                @UniqueConstraint(
                        name = "uk_supported_id_types_country_currency_key",
                        columnNames = {"country_code", "currency", "identity_type_key"}
                )
        },
        indexes = {
                // Speeds up active identity type lookups for a given country.
                @Index(
                        name = "idx_supported_id_types_country_active",
                        columnList = "country_code, is_active"
                )
        }
)
public class SupportedIdentityTypesModel {

    // Primary identifier for the supported identity rule.
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    @Column(name = "id", nullable = false, unique = true, updatable = false)
    private int id;

    // Country code (e.g., NG, KE, GH).
    @Column(name = "country_code", nullable = false, length = 3)
    private String countryCode;

    // Currency code associated with this identity rule (e.g., NGN, KES, GHS).
    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    // Machine-readable identity type key (e.g., BVN, NIN, PASSPORT, NATIONAL_ID).
    @Column(name = "identity_type_key", nullable = false, length = 40)
    private String identityTypeKey;

    // Human-readable display label shown to users during KYC/onboarding.
    @Column(name = "identity_type_name", nullable = false, length = 100)
    private String identityTypeName;

    // Indicates whether this identity type is currently enabled for selection.
    @Column(name = "is_active", nullable = false)
    private boolean isActive = true;

    // Regular expression used to validate identity number formatting before submission.
    @Column(name = "regex_pattern", nullable = false, length = 255)
    private String regexPattern;

    // Timestamp when the identity type rule was created.
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // Timestamp automatically updated when the rule changes.
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}