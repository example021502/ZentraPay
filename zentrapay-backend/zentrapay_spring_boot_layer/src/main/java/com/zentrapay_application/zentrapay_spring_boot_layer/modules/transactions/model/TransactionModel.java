package com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Data
@Table(name = "transactions")
public class TransactionModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "transaction_id", nullable = false, unique = true)
    private UUID transactionId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(nullable = false, precision = 19, scale = 4)
    private BigDecimal amount;

    @Column(nullable = false, length = 3)
    private String currency;

    @Column(nullable = false, length = 50)
    private String transactionType; // DEPOSIT, WITHDRAWAL, CREDIT, DEBIT, CRYPTO_PURCHASE

    @Column(nullable = false, length = 50)
    private String status; // PENDING, PROCESSING, COMPLETED, FAILED, COMPLETED_WITH_FAILOVER

    @Column(nullable = false, length = 50)
    private String gateway; // PAYSTACK, FLUTTERWAVE, ONAFRIQ, ZentraPayInternal

    @Column(nullable = false, length = 100)
    private String reference;

    @Column(name = "gateway_reference", length = 100)
    private String gatewayReference;

    @Column(name = "customer_email", length = 100)
    private String customerEmail;

    @Column(name = "customer_phone", length = 20)
    private String customerPhone;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(columnDefinition = "JSONB")
    private String metadata; // JSON string for additional data

    @Column(length = 255)
    private String failureReason;

    @CreationTimestamp
    @Column(nullable = false, name = "created_at")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(nullable = false, name = "updated_at")
    private LocalDateTime updatedAt;
}