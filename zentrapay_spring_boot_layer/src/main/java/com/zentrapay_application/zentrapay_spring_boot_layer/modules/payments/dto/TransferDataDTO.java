package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dto;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.Datatypes;
import java.time.LocalDateTime;
import java.util.UUID;


/**
 * {@code data} payload for POST /api/payments/initialize — field names must
 * line up 1:1 with the Flutter client's {@code AppTransaction.fromJson}
 * (lower-camel case; the client reads {@code receiverName}, so a capitalized
 * record component silently renders as "Undefined" on the home/history rows).
 * {@code amount} is a signed display string — "-GHS 100.00" (the caller is
 * always the sender on this endpoint, so the sign is a debit "-") — with the
 * currency code folded in; the client keys its credit/debit color, icon and
 * "Send Again" conditions off that leading sign.
 */
public record TransferDataDTO(
        UUID transactionId,
        UUID receiverId,
        String TXN_Ref,
        String destinationId,
        String amount,
        Datatypes.TransactionStatus status,
        String receiverName,
        String receiverIdentifier,
        LocalDateTime completedAt,
        Datatypes.TransactionType transactionType
) {
}