package com.zentrapay.backend.entity;

import com.zentrapay.backend.service.common.Datatypes;
import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

// Represents an external bill/service provider (e.g., utility, airtime, cable TV) scoped by country and category.
@Entity
@Table(
        name = "service_providers",
        uniqueConstraints = {
                // Ensures each service provider has a unique system/routing code.
                @UniqueConstraint(
                        name = "uk_service_providers_code",
                        columnNames = {"code"}
                )
        },
        indexes = {
                // Speeds up active provider lookups by country and supported service category.
                @Index(
                        name = "idx_service_providers_country_category_active",
                        columnList = "country_code, category_code, is_active"
                )
        }
)
@Data
public class ServiceProviderModel {

    // Primary identifier for the service provider record.
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    // Unique provider identifier/code used for routing and lookups.
    @Column(name = "code", nullable = false, length = 40)
    private String code;

    // Human-readable name of the service provider.
    @Column(name = "name", nullable = false, length = 120)
    private String name;

    // Restricted service category supported by the platform.
    @Enumerated(EnumType.STRING)
    @Column(name = "category_code", nullable = false, length = 30)
    private Datatypes.ServiceCategory categoryCode;

    // Aggregator or payment gateway handling fulfillment for this provider.
    @Column(name = "aggregator_gateway", length = 30)
    private String aggregatorGateway;

    // ISO 3166-1 alpha-2 country code where this provider is available (e.g., KE, NG, GH).
    @Column(name = "country_code", nullable = false, length = 2)
    private String countryCode;

    // URL or path to the provider's logo asset.
    @Column(name = "logo_url", columnDefinition = "TEXT")
    private String logoUrl;

    // Flexible JSONB payload for gateway/provider-specific configuration or fields.
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "metadata", columnDefinition = "jsonb")
    private String metadata;

    // Minimum allowed transaction amount for this provider (null if unbounded at provider level).
    @Column(name = "min_amount", precision = 19, scale = 4)
    private BigDecimal minAmount;

    // Maximum allowed transaction amount for this provider (null if unbounded at provider level).
    @Column(name = "max_amount", precision = 19, scale = 4)
    private BigDecimal maxAmount;

    // Indicates whether this provider is currently enabled for users.
    @Column(name = "is_active", nullable = false)
    private boolean isActive = true;

    // Indicates whether the provider is temporarily under maintenance.
    @Column(name = "is_maintenance_mode", nullable = false)
    private boolean isMaintenanceMode = false;

    // Timestamp when the provider record was created.
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // Timestamp automatically updated when provider configuration or status changes.
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}