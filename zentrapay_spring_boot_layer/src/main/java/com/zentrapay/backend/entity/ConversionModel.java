package com.zentrapay.backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * One currency conversion a user ran in the converter screen (history only, no money moves).
 */
@Entity
@Data
@Table(name = "conversions")
public class ConversionModel {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "conversion_id", nullable = false)
    private UUID conversionId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "from_currency_code", nullable = false, length = 3)
    private String fromCurrencyCode;

    @Column(name = "to_currency_code", nullable = false, length = 3)
    private String toCurrencyCode;

    @Column(name = "amount", nullable = false, precision = 19, scale = 4)
    private BigDecimal amount;

    @Column(name = "converted_amount", nullable = false, precision = 19, scale = 4)
    private BigDecimal convertedAmount;

    @Column(name = "rate", nullable = false, precision = 24, scale = 10)
    private BigDecimal rate;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
}
