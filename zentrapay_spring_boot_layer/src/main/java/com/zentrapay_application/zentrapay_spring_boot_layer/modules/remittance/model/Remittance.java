package com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittance.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Canonical mapping of {@code remittances} (V1__init_schema.sql). Owned entirely by
 * this module. Replaces the old RemittanceModel, which had the wrong column set
 * (missing transaction_id/recipient_country_code, receiver_id was NOT NULL though the
 * table allows a NULL receiver for non-app-user recipients).
 */
@Entity
@Data
@Table(name = "remittances")
public class Remittance {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "remittance_id", nullable = false)
    private UUID remittanceId;

    @Column(name = "sender_id", nullable = false)
    private UUID senderId;

    @Column(name = "receiver_id")
    private UUID receiverId;

    @Column(name = "transaction_id", nullable = false, unique = true)
    private UUID transactionId;

    @Column(nullable = false, precision = 19, scale = 4)
    private BigDecimal amount;

    @Column(name = "source_currency_code", nullable = false, length = 3)
    private String sourceCurrencyCode;

    @Column(name = "destination_currency_code", nullable = false, length = 3)
    private String destinationCurrencyCode;

    @Column(name = "exchange_rate", nullable = false, precision = 24, scale = 10)
    private BigDecimal exchangeRate;

    @Column(nullable = false, precision = 19, scale = 4)
    private BigDecimal fee = BigDecimal.ZERO;

    @Column(nullable = false, length = 20)
    private String status = "PENDING";

    @Column(nullable = false, length = 30)
    private String channel;

    @Column(name = "recipient_name", nullable = false, length = 120)
    private String recipientName;

    @Column(name = "recipient_phone_number", length = 20)
    private String recipientPhoneNumber;

    @Column(name = "recipient_country_code", nullable = false, length = 2)
    private String recipientCountryCode;

    @Column(nullable = false, unique = true, length = 100)
    private String reference;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
