package com.zentrapay.backend.dto.bill;

import com.zentrapay.backend.service.common.Datatypes;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;


public record BillTransactionDTO(
        UUID transactionId,
        String typeCode,
        BigDecimal amount,
        String currencyCode,
        String status,
        Datatypes.Gateway gateway,
        String reference,
        String counterpartyName,
        String counterpartyIdentifier,
        String description,
        LocalDateTime createdAt
) {
}
