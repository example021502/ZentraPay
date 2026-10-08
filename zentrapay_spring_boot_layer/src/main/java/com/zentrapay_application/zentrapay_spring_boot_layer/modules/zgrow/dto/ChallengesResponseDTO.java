package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.Datatypes;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/** A challenge catalog entry as returned by GET /api/zgrow/challenges. */
public record ChallengesResponseDTO(
        UUID id,
        String title,
        String description,
        Datatypes.ChallengeCategory category,
        Datatypes.ChallengeType challengeType,
        Integer durationDays,
        Boolean isActive,
        LocalDateTime startDate,
        LocalDateTime endDate,
        List<ChallengesTargetResponseDTO> targets
) {}