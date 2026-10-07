package com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.dtos;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.Datatypes;

import java.time.LocalDateTime;
import java.util.UUID;

public record TransactionDTO(
        UUID transactionId,
        UUID senderId,
        UUID receiverId,
        String entryId,
        String amount,
        LocalDateTime createdAt,
        String failureReason,
        Datatypes.TransactionStatus status,
        LocalDateTime updatedAt,
        Datatypes.TransactionType transactionType,
        String receiverName,
        String receiverEmail,
        String receiverPhoneNumber,
        String purpose,
        String internalReferenceId
) {
}
