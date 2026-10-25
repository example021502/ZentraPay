package com.zentrapay.backend.dto.zgrow;

import com.zentrapay.backend.service.common.Datatypes;

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