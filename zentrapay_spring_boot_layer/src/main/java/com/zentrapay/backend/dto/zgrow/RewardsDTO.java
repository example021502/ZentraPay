package com.zentrapay.backend.dto.zgrow;

import com.zentrapay.backend.service.common.Datatypes;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/** GET /api/zgrow/rewards item shape. */
public record RewardsDTO(
    int rewardId,
    Datatypes.RewardType rewardType,
    String title,
    String description,
    BigDecimal worth,
    String currencyCode,
    Boolean isActive,
    LocalDateTime createdAt,
    LocalDateTime updatedAt
) {
}
