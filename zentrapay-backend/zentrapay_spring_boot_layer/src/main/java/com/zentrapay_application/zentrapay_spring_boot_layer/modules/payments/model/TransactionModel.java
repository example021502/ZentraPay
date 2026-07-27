package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.model;

import lombok.Data;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * Transaction record for payments module.
 * <p>
 * NOTE: This class is intentionally kept minimal. The canonical transaction entity
 * is {@link com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.model.TransactionModel}
 * in the transactions module. This class exists only as a lightweight DTO-like
 * representation for internal payment flows.
 * <p>
 * For database persistence, use {@link com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.model.TransactionModel}
 * via {@link com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.repository.TransactionRepository}.
 */
// Removed @Entity annotation — this is NOT a JPA entity
// Use transactions.model.TransactionModel for persistence
@Data
public class TransactionModel {
    private UUID transactionId;

    private UUID senderId;
    private UUID receiverId;

    private UUID senderWalletId;
    private UUID receiverWalletId;

    private String gatewayAccountId;

    private BigDecimal amount;
    private String currencyCode;
    private BigDecimal feeAmount;

    private String status;
    private String referenceCode;
    private String metaData;

    private Instant createdAt;
    private Instant updatedAt;
}