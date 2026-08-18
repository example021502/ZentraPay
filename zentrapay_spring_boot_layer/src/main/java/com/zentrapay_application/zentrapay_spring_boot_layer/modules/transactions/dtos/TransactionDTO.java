package com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.dtos;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.TransactionModel;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Read model mirroring {@link TransactionModel} for the API_CONTRACT.md §5
 * {@code Transaction} response.
 * <p>
 * Field names and order match {@link TransactionModel} exactly, plus a computed
 * leading {@code sign} ("+"/"-") derived from {@code transactionType} so the
 * frontend's {@code AppTransaction}/{@code AmountText} can color a credit vs
 * debit without parsing the amount.
 */
public record TransactionDTO(
        String sign,
        UUID transactionId,
        String internalReferenceId,
        String externalReferenceId,
        UUID senderId,
        UUID receiverId,
        String senderName,
        String receiverName,
        BigDecimal amount,
        String sourceCurrencyCode,
        String destinationCurrencyCode,
        String purpose,
        String failureReason,
        String gateway,
        String metadata,
        String status,
        String transactionType,
        String senderEmail,
        String senderPhoneNumber,
        String receiverEmail,
        String receiverPhoneNumber,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}
