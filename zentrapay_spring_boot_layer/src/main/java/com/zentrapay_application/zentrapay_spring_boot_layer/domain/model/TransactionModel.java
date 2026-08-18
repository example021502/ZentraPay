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
public class TransactionModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "transaction_id", nullable = false, unique = true)
    private UUID transactionId;

    @Column(name = "internal_reference_id", nullable = false)
    private String internalReferenceId;

    @Column(name = "external_reference_id", nullable = false)
    private String externalReferenceId;

    @Column(name = "sender_id", nullable = false)
    private UUID senderId;

    @Column(name = "receiver_id", nullable = false)
    private UUID receiverId;

    @Column(name = "sender_name", nullable = false)
    private String senderName;

    @Column(name = "receiver_name", nullable = false)
    private String receiverName;

    @Column(name = "amount", nullable = false)
    private BigDecimal amount;

    @Column(name = "source_currency_code", nullable = false, length = 3)
    private String sourceCurrencyCode;

    @Column(name = "destination_currency_code", nullable = false, length = 3)
    private String destinationCurrencyCode;

    @Column(name = "purpose", nullable = false, length = 100)
    private String purpose;

    @Column(name = "failure_reason")
    private String failureReason;

    @Column(name = "gateway", nullable = false)
    private String gateway;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "metadata", columnDefinition = "jsonb")
    private String metadata;

    @Column(name = "status", nullable = false)
    private String status;

    @Column(name = "transaction_type", nullable = false, length = 50)
    private String transactionType;

    @Column(name = "sender_email", nullable = false, length = 50)
    private String senderEmail;

    @Column(name = "sender_phone_number", nullable = false, length = 50)
    private String senderPhoneNumber;

    @Column(name = "receiver_email", nullable = false, length = 50)
    private String receiverEmail;

    @Column(name = "receiver_phone_number", nullable = false, length = 50)
    private String receiverPhoneNumber;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
