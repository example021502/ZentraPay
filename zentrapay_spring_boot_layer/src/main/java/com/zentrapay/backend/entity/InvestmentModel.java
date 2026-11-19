package com.zentrapay.backend.entity;

import com.zentrapay.backend.service.common.Datatypes;
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
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "user_id", nullable = false, updatable = false)
    private UUID userId;

    @Column(name = "name", nullable = false, length = 120)
    private String name;

    @Column(name = "type", nullable = false, length = 20)
    private Datatypes.InvestmentType type = Datatypes.InvestmentType.OTHERS;

    @Column(name = "symbol", length = 20)
    private String symbol;

    @Column(name = "quantity", nullable = false, precision = 19, scale = 4)
    private BigDecimal quantity;

    @Column(name = "buy_price", nullable = false, precision = 19, scale = 4)
    private BigDecimal buyPrice;

    @Column(name = "sell_price", precision = 19, scale = 4)
    private BigDecimal sellPrice;

    @Column(name = "currency_code", nullable = false, length = 8, updatable = false)
    private String currencyCode;

    @Column(name = "sell_currency_code", nullable = false, length = 8, updatable = false)
    private String sellCurrencyCode;

    @Column(name = "status", nullable = false, length = 20)
    private Datatypes.InvestmentStatus status = Datatypes.InvestmentStatus.ACTIVE;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
