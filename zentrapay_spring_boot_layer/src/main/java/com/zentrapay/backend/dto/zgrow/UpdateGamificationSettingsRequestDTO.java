package com.zentrapay.backend.dto.zgrow;

import jakarta.validation.constraints.NotNull;

/** PUT /api/zgrow/gamification body — carries the gamified switch position. */
public record UpdateGamificationSettingsRequestDTO(
        @NotNull(message = "challengesEnabled is required")
        Boolean challengesEnabled
) {
}
