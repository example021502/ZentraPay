package com.zentrapay.backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * A ZInvest position. The cost (quantity x buy price) was taken from the user's wallet when it was
 * opened and the proceeds go back to the wallet when it is sold (see InvestmentService).
 */
@Entity
@Data
@Table(name = "investments")
public class InvestmentModel {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "investment_id", nullable = false, updatable = false)
    private UUID investmentId;

    @Column(name = "user_id", nullable = false, updatable = false)
    private UUID userId;

    @Column(name = "name", nullable = false, length = 120)
    private String name;

    // STOCK, ETF, COMMODITY, CRYPTO, OTHER (CRYPTO is refused by the service for now)
    @Column(name = "investment_type", nullable = false, length = 20)
    private String investmentType;

    @Column(name = "symbol", length = 20)
    private String symbol;

    @Column(name = "quantity", nullable = false, precision = 19, scale = 4)
    private BigDecimal quantity;

    @Column(name = "buy_price", nullable = false, precision = 19, scale = 4)
    private BigDecimal buyPrice;

    @Column(name = "currency_code", nullable = false, length = 8, updatable = false)
    private String currencyCode;

    // ACTIVE while held, CLOSED once sold
    @Column(name = "status", nullable = false, length = 20)
    private String status = "ACTIVE";

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
