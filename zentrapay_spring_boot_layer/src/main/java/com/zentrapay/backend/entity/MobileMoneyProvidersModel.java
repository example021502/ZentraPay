package com.zentrapay.backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

// Represents a mobile money provider (e.g., M-Pesa, MTN MoMo) synchronized per payment gateway and country.
@Entity
@Data
@Table(
        name = "momo_providers",
        uniqueConstraints = {
                // Prevents duplicate provider codes for the same gateway within a country.
                @UniqueConstraint(
                        name = "uk_momo_providers_gateway_code_country",
                        columnNames = {"gateway_id", "code", "country_code"}
                )
        },
        indexes = {
                // Speeds up queries for active mobile money providers in a given country.
                @Index(
                        name = "idx_momo_providers_country_active",
                        columnList = "country_code, active"
                )
        }
)
public class MobileMoneyProvidersModel {

    // Primary identifier for the mobile money provider record.
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    // Gateway-specific provider/channel code (e.g., "MPESA", "MTN") used when routing payouts or collections.
    @Column(name = "code", nullable = false, length = 32)
    private String code;

    // Display name of the mobile money operator.
    @Column(name = "name", nullable = false, length = 80)
    private String name;

    // ISO country code where this provider operates (e.g., "KE", "NG", "GH").
    @Column(name = "country_code", nullable = false, length = 3)
    private String countryCode;

    // Indicates whether this provider is currently enabled for use.
    @Column(name = "active", nullable = false)
    private Boolean active = true;

    // Identifier of the payment gateway that supplies and processes this provider.
    @Column(name = "gateway_id", nullable = false)
    private UUID gatewayId;

    // Timestamp when this record was first created.
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // Timestamp automatically updated whenever this record is modified.
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}