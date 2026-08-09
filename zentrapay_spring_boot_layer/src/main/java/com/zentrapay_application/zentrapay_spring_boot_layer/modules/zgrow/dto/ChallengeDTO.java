package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto;

import java.util.UUID;

public record ChallengeDTO(
        UUID challengeId,
        String title,
        String description,
        String category,
        Integer durationDays,
        Integer pointsReward,
        String difficulty,
        long participantsCount,
        boolean joined,
        int progressPercent
) {
}
