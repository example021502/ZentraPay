package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zinvest.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Data
@Table(name = "investments")
public class InvestmentModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "investment_id", nullable = false, unique = true)
    private UUID investmentId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String type; // STOCK, CRYPTO, COMMODITY, ETF

    @Column(nullable = false)
    private String symbol; // AAPL, BTC, GOLD, etc.

    @Column(nullable = false, precision = 19, scale = 4)
    private BigDecimal quantity;

    @Column(nullable = false, precision = 19, scale = 4)
    private BigDecimal buyPrice;

    @Column(precision = 19, scale = 4)
    private BigDecimal currentPrice;

    @Column(nullable = false)
    private String currency;

    @Column(nullable = false)
    private String status = "ACTIVE"; // ACTIVE, SOLD, CLOSED

    @CreationTimestamp
    @Column(nullable = false, name = "created_at")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(nullable = false, name = "updated_at")
    private LocalDateTime updatedAt;
}