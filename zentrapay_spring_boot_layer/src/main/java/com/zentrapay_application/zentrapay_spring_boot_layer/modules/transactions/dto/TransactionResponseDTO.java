package com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.dto;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.Transaction;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * {@code Transaction} shape per API contract §5:
 * {@code {transactionId,typeCode,amount,currencyCode,status,gateway,reference,
 * counterpartyName,counterpartyIdentifier,description,createdAt}}.
 * <p>
 * Shared across {@code /api/transactions}, {@code /api/payments} and
 * {@code /api/cards/{cardId}/pay} responses, all of which return the same
 * canonical {@link Transaction} row shape.
 * <p>
 * {@code amount} is a {@link String} (via {@code BigDecimal.toPlainString()})
 * rather than a numeric JSON type — the contract requires every money field
 * on the wire to be a decimal string so the client never touches floating
 * point precision.
 */
public record TransactionResponseDTO(
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
    public static TransactionResponseDTO from(Transaction transaction) {
        return new TransactionResponseDTO(
                transaction.getTransactionId(),
                transaction.getTypeCode(),
                transaction.getAmount().toPlainString(),
                transaction.getCurrencyCode(),
                transaction.getStatus(),
                transaction.getGateway(),
                transaction.getReference(),
                transaction.getCounterpartyName(),
                transaction.getCounterpartyIdentifier(),
                transaction.getDescription(),
                transaction.getCreatedAt()
        );
    }
}
