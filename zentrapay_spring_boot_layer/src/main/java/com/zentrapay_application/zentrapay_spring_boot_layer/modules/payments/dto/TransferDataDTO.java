package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dto;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.Datatypes;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;


public record TransferDataDTO(
        UUID transactionId,
        UUID receiverId,
        String TXN_Ref,
        String destinationId,
        BigDecimal amount,
        String currencyCode,
        Datatypes.TransactionStatus status,
        String ReceiverName,
        String receiverIdentifier,
        LocalDateTime completedAt,
        Datatypes.TransactionType transactionType
) {
}