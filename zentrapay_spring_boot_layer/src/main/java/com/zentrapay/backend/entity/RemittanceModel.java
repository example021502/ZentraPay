package com.zentrapay.backend.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

// Stores cross-border remittance metadata and status linked to the sender's debit leg in `transactions`.
@Entity
@Data
@Table(
        name = "remittances",
        uniqueConstraints = {
                // Prevents duplicate remittance creation for the same sender and idempotency key.
                @UniqueConstraint(
                        name = "uk_remittances_sender_idempotency",
                        columnNames = {"sender_id", "idempotency_key"}
                ),
                // Ensures every remittance has a unique external/internal reference.
                @UniqueConstraint(
                        name = "uk_remittances_reference",
                        columnNames = {"reference"}
                )
        },
        indexes = {
                // Speeds up lookups for a sender's remittances filtered by lifecycle status.
                @Index(
                        name = "idx_remittances_sender_status",
                        columnList = "sender_id, status"
                ),
                // Speeds up resolving a remittance record from its linked ledger transaction ID.
                @Index(
                        name = "idx_remittances_transaction_id",
                        columnList = "transaction_id"
                )
        }
)
public class RemittanceModel {

    // Primary identifier for the remittance record.
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    // Sender user ID initiating the cross-border transfer.
    @Column(name = "sender_id", nullable = false, updatable = false)
    private UUID senderId;

    // Recipient user ID when the recipient is an existing ZentraPay user; null otherwise.
    @Column(name = "receiver_id")
    private UUID receiverId;

    // Points to the sender's debit leg in the `transactions` table.
    @Column(name = "transaction_id", nullable = false, updatable = false)
    private UUID transactionId;

    // Client-supplied idempotency key scoped per sender to safely retry requests.
    @Column(name = "idempotency_key", nullable = false, length = 100, updatable = false)
    private String idempotencyKey;

    // Amount debited in the source currency before/at conversion.
    @Column(name = "amount", nullable = false, precision = 19, scale = 4)
    private BigDecimal amount;

    // ISO currency code of the sender's source leg (e.g., KES, NGN, GHS).
    @Column(name = "source_currency_code", nullable = false, length = 3)
    private String sourceCurrencyCode;

    // ISO currency code of the destination payout currency.
    @Column(name = "destination_currency_code", nullable = false, length = 3)
    private String destinationCurrencyCode;

    // Applied FX conversion rate between source and destination currencies.
    @Column(name = "exchange_rate", nullable = false, precision = 24, scale = 10)
    private BigDecimal exchangeRate;

    // Remittance/transfer fee charged for the operation.
    @Column(name = "fee", nullable = false, precision = 19, scale = 4)
    private BigDecimal fee;

    // Current remittance lifecycle status (e.g., PENDING, PROCESSING, COMPLETED, FAILED).
    @Column(name = "status", nullable = false, length = 20)
    private String status;

    // Payout or delivery channel code used for fulfillment.
    @Column(name = "channel", nullable = false, length = 30)
    private String channel;

    // Full name of the intended recipient.
    @Column(name = "recipient_name", nullable = false, length = 120)
    private String recipientName;

    // Optional recipient phone number for mobile money or payout notification.
    @Column(name = "recipient_phone_number", length = 20)
    private String recipientPhoneNumber;

    // ISO country code of the recipient destination.
    @Column(name = "recipient_country_code", nullable = false, length = 2)
    private String recipientCountryCode;

    // Unique reference code for tracking and gateway/support correlation.
    @Column(name = "reference", nullable = false, length = 100)
    private String reference;

    // Timestamp when the remittance record was created.
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // Timestamp automatically updated whenever the remittance record is modified.
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}