package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.TransactionModel;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;


/**
 * Local mirror of the API_CONTRACT.md §5 {@code Transaction} response shape,
 * built from {@link TransactionModel}.
 * Kept local to this module rather than importing another module's copy —
 * see billProviders.dto.TransactionDTO, which documents the same choice.
 * <p>
 * {@code amount} is a sign-prefixed string ("+12.50" / "-12.50"), matching
 * the frontend's {@code AppTransaction}/{@code AmountText} contract, which
 * colors an amount by whether its string starts with '+'.
 */
public record TransactionDTO(
        String sign,
        UUID transactionId,
        String intenalReferenceId,
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
