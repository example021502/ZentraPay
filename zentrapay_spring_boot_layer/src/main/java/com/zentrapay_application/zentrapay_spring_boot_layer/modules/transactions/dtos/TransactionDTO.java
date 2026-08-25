package com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.dtos;

import java.time.LocalDateTime;
import java.util.UUID;

public record TransactionDTO(
        UUID transactionId,
        UUID receiverId,
        String entryId,
        String amount,
        LocalDateTime createdAt,
        String failureReason,
        String status,
        LocalDateTime updatedAt,
        String transactionType,
        String receiverName,
        String receiverEmail,
        String receiverPhoneNumber,
        String purpose,
        String internalReferenceId
) {
}
