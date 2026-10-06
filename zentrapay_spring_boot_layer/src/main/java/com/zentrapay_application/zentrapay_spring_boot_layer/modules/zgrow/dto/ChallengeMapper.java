package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.ChallengesTargetModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.Datatypes;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/** GET /api/notifications item shape. */
public record ChallengesProgressResponseDTO(
        UUID id,
        BigDecimal amountContributed,
        BigDecimal newTotalAmount,
        UUID transactionReference,
        String notes,
        LocalDateTime createdAt
) {
}
