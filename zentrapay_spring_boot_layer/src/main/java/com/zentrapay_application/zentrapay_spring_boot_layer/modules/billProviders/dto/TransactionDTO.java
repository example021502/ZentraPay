package com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Local mirror of the API_CONTRACT.md §5 {@code Transaction} response shape, built from
 * {@link com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.Transaction}.
 * Kept local to this module (rather than importing a DTO owned by the transactions
 * module, which a parallel agent is actively rewriting) to avoid cross-module coupling.
 */
public record TransactionDTO(
        UUID transactionId,
        String typeCode,
        BigDecimal amount,
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
