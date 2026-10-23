package com.zentrapay.backend.entity;

import com.zentrapay.backend.service.common.Datatypes;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * One row per savings deposit: the per-user, per-currency savings ledger.
 * The "Overall Savings" hero total is `SUM(amount)` grouped by currency.
 */
@Entity
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(
        name = "user_savings",
        indexes = {
                @Index(name = "idx_user_savings_user_created", columnList = "user_id, created_at DESC"),
                @Index(name = "idx_user_savings_user_currency", columnList = "user_id, currency_code")
        }
)
public class UserSavingsModel {

    @Id

    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "saving_id", nullable = false, updatable = false)
    private UUID savingId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @Column(name = "amount", nullable = false, precision = 19, scale = 4)
    private BigDecimal amount;

    @Enumerated(EnumType.STRING)
    @Column(name = "source", nullable = false, length = 30)
    private Datatypes.SavingsSource source;

    @Column(name = "reference_id")
    private UUID referenceId;

    @Column(name = "note", length = 255)
    private String note;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
