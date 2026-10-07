package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/** One contribution event in a user's challenge progress ledger. */
public record ChallengesProgressResponseDTO(
        UUID id,
        BigDecimal amountContributed,
        BigDecimal newTotalAmount,
        UUID transactionReference,
        String notes,
        LocalDateTime createdAt
) {
}
