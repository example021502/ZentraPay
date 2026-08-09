package com.zentrapay_application.zentrapay_spring_boot_layer.modules.serviceProviders.models;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Canonical mapping of {@code service_providers} (V1__init_schema.sql). Rewritten to
 * match the table exactly — the previous version of this entity referenced a
 * nonexistent "region" column and a "category" column instead of "category_code",
 * which would have failed {@code spring.jpa.hibernate.ddl-auto=validate} at boot.
 */
@Entity
@Table(name = "service_providers")
@Data
public class ServiceProviderModel {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "provider_id", nullable = false)
    private UUID providerId;

    @Column(name = "provider_code", nullable = false, unique = true, length = 40)
    private String providerCode;

    @Column(name = "provider_name", nullable = false, length = 120)
    private String providerName;

    @Column(name = "category_code", nullable = false, length = 30)
    private String categoryCode;

    @Column(name = "aggregator_gateway", length = 30)
    private String aggregatorGateway;

    @Column(name = "country_code", nullable = false, length = 2)
    private String countryCode;

    @Column(name = "logo_url", columnDefinition = "TEXT")
    private String logoUrl;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb")
    private String metadata;

    @Column(name = "min_amount", precision = 19, scale = 2)
    private BigDecimal minAmount;

    @Column(name = "max_amount", precision = 19, scale = 2)
    private BigDecimal maxAmount;

    @Column(name = "is_active", nullable = false)
    private boolean isActive = true;

    @Column(name = "is_maintenance_mode", nullable = false)
    private boolean isMaintenanceMode = false;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
