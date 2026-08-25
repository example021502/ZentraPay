package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * Canonical mapping of {@code gateway_countries} (V9__gateway_directory_consolidation.sql).
 * This is now THE supported-countries table: it only ever contains countries the
 * connected gateways (Paystack / Flutterwave / Onafriq) actually support, kept
 * fresh by the scheduled {@code GatewayDirectorySyncService}. ISO 3166-1 alpha-2
 * country code is the natural key.
 */
@Entity
@Data
@Table(name = "gateway_countries")
public class GatewayCountryModel {
    @Id
    @Column(name = "country_code", nullable = false, length = 3)
    private String countryCode;

    @Column(name = "country_name", nullable = false, length = 80)
    private String countryName;

    @Column(name = "iso3_code", length = 3)
    private String iso3Code;

    @Column(name = "dial_code", length = 6)
    private String dialCode;

    @Column(name = "region", length = 40)
    private String region;

    /** Default payout/settlement currency for this country. */
    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    /** Comma-separated gateways supporting this country, e.g. "paystack,flutterwave". */
    @Column(name = "gateways", nullable = false)
    private String gateways;

    @Column(name = "is_default", nullable = false)
    private boolean isDefault;

    @Column(name = "active", nullable = false)
    private boolean active;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}