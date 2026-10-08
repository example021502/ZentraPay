// Always add inline comments for code readability and maintenance
package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.Datatypes;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.type.SqlTypes;
import tools.jackson.databind.JsonNode;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

// JPA Entity representing the central transactions ledger
@Entity
@Data // Automatically generates getters, setters, equals, hashCode, and toString
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(
        name = "transactions",
        indexes = {
                // High-frequency lookup by internal idempotency reference
                @Index(name = "idx_txn_internal_ref", columnList = "internal_reference_id", unique = true),
                // External reference lookup for webhooks / callbacks
                @Index(name = "idx_txn_external_ref", columnList = "external_reference_id"),
                // User history query optimization
                @Index(name = "idx_txn_sender_created", columnList = "sender_id, created_at DESC"),
                @Index(name = "idx_txn_receiver_created", columnList = "receiver_id, created_at DESC"),
                // Worker poller query optimization for pending callbacks
                @Index(name = "idx_txn_status_created", columnList = "status, created_at")
        }
)
public class TransactionModel {

    // Primary Key
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "transaction_id", nullable = false, updatable = false)
    private UUID transactionId;

    // Double-entry ledger entry identifier
    @Column(name = "entry_id", nullable = false, length = 64)
    private String entryId;

    // Idempotency keys & References
    @Column(name = "internal_reference_id", nullable = false, unique = true, length = 64)
    private String internalReferenceId;

    // Nullable at initiation; populated asynchronously when Telco/Gateway responds
    @Column(name = "external_reference_id", length = 64)
    private String externalReferenceId;

    // Financial Metrics
    @Column(name = "amount", nullable = false, precision = 19, scale = 4)
    private BigDecimal amount;

    @Column(name = "source_currency_code", nullable = false, length = 3)
    private String sourceCurrencyCode;

    @Column(name = "destination_currency_code", nullable = false, length = 3)
    private String destinationCurrencyCode;

    // Enums for Domain Integrity
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private Datatypes.TransactionStatus status;

    @Enumerated(EnumType.STRING)
    @Column(name = "transaction_type", nullable = false, length = 30)
    private Datatypes.TransactionType transactionType;

    @Enumerated(EnumType.STRING)
    @Column(name = "gateway", nullable = false, length = 32)
    private Datatypes.PaymentGateway gateway;

    // Sender Metadata
    @Column(name = "sender_id", nullable = false)
    private UUID senderId;

    @Column(name = "sender_name", nullable = false, length = 150)
    private String senderName;

    @Column(name = "sender_email", nullable = false, length = 150)
    private String senderEmail;

    @Column(name = "sender_phone_number", nullable = false, length = 20)
    private String senderPhoneNumber;

    // Receiver Metadata
    @Column(name = "receiver_id", nullable = false)
    private UUID receiverId;

    @Column(name = "receiver_name", nullable = false, length = 150)
    private String receiverName;

    @Column(name = "receiver_email", nullable = false, length = 150)
    private String receiverEmail;

    @Column(name = "receiver_phone_number", nullable = false, length = 20)
    private String receiverPhoneNumber;

    // Routing Details
    @Column(name = "destination_identifier", nullable = false, length = 100)
    private String destinationIdentifier;

    @Column(name = "purpose", nullable = false, length = 255)
    private String purpose;

    // Failure Auditing
    @Column(name = "failure_reason", length = 255)
    private String failureReason;

    // Dynamic Metadata
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "metadata", columnDefinition = "jsonb")
    private JsonNode metadata;

    // Timestamps
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}