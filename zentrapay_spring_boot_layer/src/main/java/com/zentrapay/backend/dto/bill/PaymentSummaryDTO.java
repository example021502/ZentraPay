package com.zentrapay.backend.dto.bill;

import java.util.UUID;

public record PaymentSummaryDTO(
        UUID paymentId,
        String status
) {
}
