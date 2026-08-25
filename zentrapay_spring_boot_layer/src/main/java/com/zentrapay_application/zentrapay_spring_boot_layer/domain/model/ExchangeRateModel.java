package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Canonical mapping of {@code exchange_rates} (V1__init_schema.sql).
 * Append-only FX history: the current rate for a pair is the row with the
 * latest {@code effective_at} (see RemittanceService#resolveRate — direct,
 * inverted, or USD-triangulated lookup).
 */
@Entity
@Data
@Table(name = "exchange_rates")
public class ExchangeRateModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "rate_id", nullable = false)
    private UUID rateId;

    @Column(name = "base_currency_code", nullable = false, length = 3)
    private String baseCurrencyCode;

    @Column(name = "quote_currency_code", nullable = false, length = 3)
    private String quoteCurrencyCode;

    @Column(name = "rate", nullable = false, precision = 24, scale = 10)
    private BigDecimal rate;

    @Column(name = "source", length = 30)
    private String source;

    @Column(name = "effective_at", nullable = false)
    private LocalDateTime effectiveAt;
}