package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Canonical mapping of {@code remittances} (V1__init_schema.sql). One row per
 * cross-border send; the money-movement legs live in {@code transactions}
 * ({@code transactionId} points at the sender's debit leg). The legacy FKs to
 * the dropped {@code countries}/{@code currencies} tables were removed by
 * V9__gateway_directory_consolidation.sql — supported-country/currency checks
 * now run against {@code gateway_countries}/{@code gateway_currencies}.
 */
@Entity
@Data
@Table(name = "remittances")
public class RemittanceModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "remittance_id", nullable = false)
    private UUID remittanceId;

    @Column(name = "sender_id", nullable = false)
    private UUID senderId;

    /** NULL when the receiver isn't an app user. */
    @Column(name = "receiver_id")
    private UUID receiverId;

    @Column(name = "transaction_id", nullable = false)
    private UUID transactionId;

    @Column(name = "amount", nullable = false, precision = 19, scale = 4)
    private BigDecimal amount;

    @Column(name = "source_currency_code", nullable = false, length = 3)
    private String sourceCurrencyCode;

    @Column(name = "destination_currency_code", nullable = false, length = 3)
    private String destinationCurrencyCode;

    @Column(name = "exchange_rate", nullable = false, precision = 24, scale = 10)
    private BigDecimal exchangeRate;

    @Column(name = "fee", nullable = false, precision = 19, scale = 4)
    private BigDecimal fee;

    @Column(name = "status", nullable = false, length = 20)
    private String status;

    @Column(name = "channel", nullable = false, length = 30)
    private String channel;

    @Column(name = "recipient_name", nullable = false, length = 120)
    private String recipientName;

    @Column(name = "recipient_phone_number", length = 20)
    private String recipientPhoneNumber;

    @Column(name = "recipient_country_code", nullable = false, length = 2)
    private String recipientCountryCode;

    @Column(name = "reference", nullable = false, unique = true, length = 100)
    private String reference;

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}