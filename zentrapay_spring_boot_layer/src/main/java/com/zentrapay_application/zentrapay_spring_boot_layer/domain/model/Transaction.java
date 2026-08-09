package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * The canonical, single money-movement ledger. Every module that changes a
 * wallet balance (payments, bill_payments, savings, loans, investments,
 * remittance, cards, rewards) writes exactly one row here — this replaces
 * the old split between transactions.TransactionModel and history's reuse
 * of it, plus the ad-hoc bespoke bookkeeping some other modules did.
 */
@Entity
@Data
@Table(name = "transactions")
public class Transaction {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "transaction_id", nullable = false)
    private UUID transactionId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "wallet_id")
    private UUID walletId;

    @Column(name = "type_code", nullable = false, length = 30)
    private String typeCode;

    @Column(nullable = false, precision = 19, scale = 4)
    private BigDecimal amount;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @Column(nullable = false, length = 20)
    private String status = "PENDING";

    @Column(length = 30)
    private String gateway;

    @Column(nullable = false, unique = true, length = 100)
    private String reference;

    @Column(name = "gateway_reference", length = 100)
    private String gatewayReference;

    @Column(name = "counterparty_user_id")
    private UUID counterpartyUserId;

    @Column(name = "counterparty_name", length = 120)
    private String counterpartyName;

    @Column(name = "counterparty_identifier", length = 120)
    private String counterpartyIdentifier;

    @Column(columnDefinition = "TEXT")
    private String description;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb")
    private String metadata;

    @Column(name = "failure_reason", columnDefinition = "TEXT")
    private String failureReason;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
