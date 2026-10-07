package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.Datatypes;

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
