package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.Datatypes;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/** A user's enrollment in a challenge, with their progress and ledger. */
public record UserChallengesResponseDTO(
        UUID id,
        UUID userId,
        ChallengesResponseDTO challenge,
        Datatypes.ChallengeStatus status,
        BigDecimal currentAmount,
        BigDecimal targetAmount,
        Double progressPercentage, // Pre-calculated for Flutter progress bar UI
        LocalDateTime startedAt,
        LocalDateTime endsAt,
        LocalDateTime completedAt,
        List<ChallengesProgressResponseDTO> progressLogs
) {
}
