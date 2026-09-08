package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.Datatypes;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/** GET /api/notifications item shape. */
public record RewardsDTO(
    int rewardId,
    Datatypes.RewardTypeEnum rewardType,
    String title,
    String description,
    BigDecimal worth,
    String currencyCode,
    Boolean isActive,
    LocalDateTime createdOn,
    LocalDateTime updatedOn
) {
}
