package com.zentrapay.backend.dto.zgrow;

import com.zentrapay.backend.service.common.Datatypes;

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