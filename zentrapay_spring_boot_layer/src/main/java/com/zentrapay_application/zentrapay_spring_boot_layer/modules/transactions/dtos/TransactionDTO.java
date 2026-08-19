package com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.dtos;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Local mirror of the API_CONTRACT.md §5 {@code Transaction} response shape,
 * built from {@link com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.Transaction}.
 * Kept local to this module rather than importing another module's copy —
 * see billProviders.dto.TransactionDTO, which documents the same choice.
 * <p>
 * {@code amount} is a sign-prefixed string ("+12.50" / "-12.50"), matching
 * the frontend's {@code AppTransaction}/{@code AmountText} contract, which
 * colors an amount by whether its string starts with '+'.
 */
public record TransactionDTO(
        UUID transactionId,
        String typeCode,
        String amount,
        String currencyCode,
        String status,
        String gateway,
        String reference,
        String counterpartyName,
        String counterpartyIdentifier,
        String description,
        LocalDateTime createdAt
) {
}
