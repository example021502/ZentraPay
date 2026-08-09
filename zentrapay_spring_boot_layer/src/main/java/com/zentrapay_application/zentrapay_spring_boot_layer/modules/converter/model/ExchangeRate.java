package com.zentrapay_application.zentrapay_spring_boot_layer.modules.converter.model;

import jakarta.persistence.*;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Canonical mapping of {@code exchange_rates} (V1__init_schema.sql) — an append-only
 * rate history; "the" current rate for a pair is the row with the latest effective_at
 * (see {@link com.zentrapay_application.zentrapay_spring_boot_layer.modules.converter.service.ConverterService}),
 * not a separate mutable "current rate" table.
 */
@Entity
@Data
@Table(name = "exchange_rates")
public class ExchangeRate {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "rate_id", nullable = false)
    private UUID rateId;

    @Column(name = "base_currency_code", nullable = false, length = 3)
    private String baseCurrencyCode;

    @Column(name = "quote_currency_code", nullable = false, length = 3)
    private String quoteCurrencyCode;

    @Column(nullable = false, precision = 24, scale = 10)
    private BigDecimal rate;

    @Column(nullable = false, length = 40)
    private String source;

    @Column(name = "effective_at", nullable = false)
    private LocalDateTime effectiveAt;
}
