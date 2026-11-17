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
 * <p>
 * currency, and a cross-border payment to this country arrives in it. There is no separate currencies table.
 */
@Entity
@Data
@Table(name = "currencies")
public class CurrenciesModel {
    @Id
    @Column(name = "code", nullable = false, length = 3)
    private String code;

    @Column(name = "currency_name", nullable = false, length = 80)
    private String currencyName;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @Column(name = "active", nullable = false)
    private boolean active;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
