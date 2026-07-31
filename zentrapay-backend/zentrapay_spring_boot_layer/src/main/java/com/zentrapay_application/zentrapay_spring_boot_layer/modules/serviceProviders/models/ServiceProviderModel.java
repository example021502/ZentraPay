package com.zentrapay_application.zentrapay_spring_boot_layer.modules.serviceProviders.models;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "service_providers")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ServiceProviderModel {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "provider_id", nullable = false, unique = true, updatable = false)
    private UUID providerId;

    @Column(name = "provider_code", nullable = false, unique = true, length = 50)
    private String providerCode;

    @Column(name = "provider_name", nullable = false, length = 100)
    private String providerName;

    @Column(name = "category", nullable = false, length = 50)
    private String category;

    @Column(name = "aggregator_gateway", nullable = false, length = 50)
    private String aggregatorGateway;

    @Column(name = "region", nullable = false, length = 50)
    private String region;

    @Column(name = "logo_url", columnDefinition = "TEXT")
    private String logoUrl;

    @Column(name = "metadata", columnDefinition = "jsonb", nullable = false)
    private String metadata;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive;

    @Column(name = "is_maintenance_mode", nullable = false)
    private Boolean isMaintenanceMode;

    @Column(name = "min_amount", nullable = false, precision = 19, scale = 2)
    private BigDecimal minAmount;

    @Column(name = "max_amount", precision = 19, scale = 2)
    private BigDecimal maxAmount;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;
}