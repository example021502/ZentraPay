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

@Entity
@Data
@Table(name = "transactions")
public class TransactionModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "transaction_id", nullable = false)
    private UUID transactionId;

    @Column(name = "entry_id", nullable = false)
    private String entryId;

    @Column(name = "amount", nullable = false)
    private BigDecimal amount;

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "failure_reason", nullable = true, length = 255)
    private String failureReason;

    @Column(name = "gateway", nullable = false, length = 32)
    private String gateway;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "metadata", columnDefinition = "jsonb")
    private String metadata;

    @Column(name = "status", nullable = false)
    private String status;

    @CreationTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @Column(name = "transaction_type", nullable = false)
    private String transactionType;

    @Column(name = "sender_id", nullable = false)
    private UUID senderId;

    @Column(name = "receiver_id", nullable = false)
    private UUID receiverId;

    @Column(name = "sender_name", nullable = false)
    private String senderName;

    @Column(name = "receiver_name", nullable = false)
    private String receiverName;

    @Column(name = "source_currency_code", nullable = false)
    private String sourceCurrencyCode;

    @Column(name = "destination_currency_code", nullable = false)
    private String destinationCurrencyCode;

    @Column(name = "destination_identifier", nullable = false)
    private String destinationIdentifier;

    @Column(name = "purpose", nullable = false)
    private String purpose;

    @Column(name = "sender_email", nullable = false)
    private String senderEmail;

    @Column(name = "sender_phone_number", nullable = false)
    private String senderPhoneNumber;

    @Column(name = "receiver_email", nullable = false)
    private String receiverEmail;

    @Column(name = "receiver_phone_number", nullable = false)
    private String receiverPhoneNumber;

    @Column(name = "internal_reference_id", nullable = false)
    private String internalReferenceId;

    @Column(name = "external_reference_id", nullable = false)
    private String externalReferenceId;

}
