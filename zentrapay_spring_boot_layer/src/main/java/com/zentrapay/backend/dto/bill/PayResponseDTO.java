package com.zentrapay.backend.dto.bill;

public record PayResponseDTO(
        PaymentSummaryDTO payment,
        BillTransactionDTO transaction
) {
}
