package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.Datatypes;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * A single target tier and its reward definition. Kept as a record (like the
 * rest of the ZGrow DTOs) so it gets a real canonical constructor instead of
 * relying on the package-private one Lombok's {@code @Builder} generates.
 */
public record ChallengesTargetResponseDTO(
    UUID id,
    BigDecimal targetAmount,
    Datatypes.RewardType rewardType,
    String rewardValue,
    Integer tierLevel
) {}