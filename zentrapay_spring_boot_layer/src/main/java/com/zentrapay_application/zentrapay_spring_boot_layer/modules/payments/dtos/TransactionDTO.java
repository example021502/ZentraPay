package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

public record TransactionDTO(
UUID transactionId,
String amount,
LocalDateTime createdAt,
String failureReason,
String gateway,
@JdbcTypeCode(SqlTypes.JSON)
String metadata,
String status,
@CreationTimestamp
LocalDateTime updatedAt,
String transactionType,
String receiverName,
String purpose,
String internalReferenceId,
String externalReferenceId,
String destinationIdentifier
) {
}
