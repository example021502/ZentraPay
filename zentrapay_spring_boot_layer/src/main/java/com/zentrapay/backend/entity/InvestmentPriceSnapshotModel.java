package com.zentrapay.backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * One recorded price for a position. The newest row is the position's current price; the first one
 * is written when the position is opened (at the buy price).
 */
@Entity
@Data
@Table(name = "investment_price_snapshots")
public class InvestmentPriceSnapshotModel {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "investment_id", nullable = false, updatable = false)
    private UUID investmentId;

    @Column(name = "price", nullable = false, precision = 19, scale = 4)
    private BigDecimal price;

    @Column(name = "action", nullable = false)
    private ActionType action = ActionType.BUY;

    @CreationTimestamp
    @Column(name = "recorded_at", nullable = false, updatable = false)
    private LocalDateTime recordedAt;

    private enum ActionType {
        BUY("buy"),
        SELL("sell");
        private final String action;

        ActionType(String action) {
            this.action = action;
        }

        public String getActionType() {
            return action;
        }
    }
}
