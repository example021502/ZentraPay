package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * Canonical mapping of {@code gateway_currencies} (V9__gateway_directory_consolidation.sql).
 * THE supported-currencies table: every currency the connected gateways can
 * move money in, refreshed by the scheduled {@code GatewayDirectorySyncService}.
 * ISO 4217 currency code is the natural key.
 */
@Entity
@Data
@Table(name = "gateway_currencies")
public class GatewayCurrencyModel {
    @Id
    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @Column(name = "currency_name", nullable = false, length = 60)
    private String currencyName;

    @Column(name = "symbol", nullable = false, length = 8)
    private String symbol;

    @Column(name = "is_crypto", nullable = false)
    private boolean isCrypto;

    @Column(name = "decimal_places", nullable = false)
    private short decimalPlaces;

    /** Home country of the currency ('' when it spans multiple countries, e.g. EUR). */
    @Column(name = "country_code", nullable = false, length = 3)
    private String countryCode;

    /** Comma-separated gateways supporting this currency. */
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