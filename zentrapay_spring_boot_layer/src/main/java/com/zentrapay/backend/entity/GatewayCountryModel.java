package com.zentrapay.backend.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * Canonical mapping of {@code gateway_countries} - the ONLY reference table for places and money.
 * It contains the countries the connected gateways (Paystack / Flutterwave / Onafriq) support, kept
 * fresh by the scheduled {@code GatewayDirectorySyncService}. ISO 3166-1 alpha-2 country code is the
 * natural key.
 *
 * <p>{@link #defaultCurrency} is what restricts payments: a user registered in this country pays in this
 * currency, and a cross-border payment to this country arrives in it. There is no separate currencies table.
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

    /** The currency (ISO 4217 code) people registered in this country pay in, and cross-border payments arrive in. */
    @Column(name = "default_currency", nullable = false, length = 8)
    private String defaultCurrency;

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
