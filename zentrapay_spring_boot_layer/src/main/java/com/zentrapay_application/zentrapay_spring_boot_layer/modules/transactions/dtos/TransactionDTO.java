package com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.dtos;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.Datatypes;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Slim history row — exactly the fields the Flutter client's
 * {@code AppTransaction.fromJson} consumes, no more. Anything extra here
 * becomes an "Undefined" gap on the client when the shapes drift, so keep
 * this record locked to the frontend model:
 * transactionId, receiverId, TXN_Ref, destinationId, amount, status,
 * receiverName, receiverIdentifier, completedAt, transactionType.
 * <p>
 * {@code amount} is a pre-signed display string — "+GHS 100.00" for a credit
 * (the authenticated user is the receiver) or "-GHS 100.00" for a debit —
 * with the currency code folded in. The client keys its credit/debit colors,
 * icons and "Send Again" visibility off that leading sign.
 */
public record TransactionDTO(
        UUID transactionId,
        UUID receiverId,
        // Ledger's unique, human-quotable reference (internalReferenceId on
        // the entity); exposed under its legacy client-facing name.
        String TXN_Ref,
        // Routing target the payment was sent to (zentag/phone/bank id).
        String destinationId,
        String amount,
        Datatypes.TransactionStatus status,
        String receiverName,
        // Phone number of the counterparty — the client's searchable identifier.
        String receiverIdentifier,
        LocalDateTime completedAt,
        Datatypes.TransactionType transactionType
) {
}
