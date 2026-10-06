package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.ChallengesTargetModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.Datatypes;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/** GET /api/notifications item shape. */
public record UserChallengesResponseDTO(
        UUID id,
        UUID userId,
        String description,
        Datatypes.ChallengeCategory category,
        Datatypes.ChallengeType challengeType,
        Integer durationDays,
        Boolean isActive,
        LocalDateTime startDate,
        LocalDateTime endDate,
        List<ChallengesTargetModel> targets,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}
