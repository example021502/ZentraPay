package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto;

import java.util.UUID;

/**
 * A single challenge as seen by one user (API_CONTRACT.md §14) —
 * {@code participantsCount} is a same-challenge aggregate across all users
 * (COUNT only, never who joined); {@code joined}/{@code progressPercent} are
 * specific to the requesting user.
 */
public record ChallengeItemDTO(
        UUID challengeId,
        String category,
        String title,
        String description,
        Integer durationDays,
        Integer pointsReward,
        String difficulty,
        long participantsCount,
        boolean joined,
        int progressPercent
) {
}
