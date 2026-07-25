package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Data //
@Table(name = "transactions")
public class TransactionModel {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "transaction_id", nullable = false, unique = true)
    private UUID transactionId;

    @Column(name = "sender_id", nullable = false)
    private UUID senderId;

    @Column(nullable = false, name = "receiver_id")
    private UUID receiverId;

    @Column(name = "sender_wallet_id", nullable = false)
    private UUID senderWalletId;

    @Column(name = "receiver_wallet_id", nullable = false)
    private UUID receiverWalletId;

    @Column(name = "gateway_account_id", nullable = false)
    private String gatewayAccountId;

    @Column(nullable = false, name = "amount")
    private BigDecimal amount;

    @Column(nullable = false, name = "currency_code")
    private String currencyCode;

    @Column(nullable = false, name = "fee_amount")
    private BigDecimal feeAmount;

    @Column(nullable = false, name = "Status")
    private String status;

    @Column(nullable = false, name = "reference_code")
    private String referenceCode;

    @Column(nullable = false, name = "meta_data")
    private String metaData;

    @CreationTimestamp
    @Column(nullable = false, name = "created_at")
    private Instant createdAt;

    @CreationTimestamp
    @Column(nullable = false, name = "updated_at")
    private Instant updatedAt;
}