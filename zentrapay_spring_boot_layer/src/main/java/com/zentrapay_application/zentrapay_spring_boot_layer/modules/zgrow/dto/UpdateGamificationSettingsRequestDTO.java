package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto;

import jakarta.validation.constraints.NotNull;

/** PUT /api/zgrow/gamification body — carries the gamified switch position. */
public record UpdateGamificationSettingsRequestDTO(
        @NotNull(message = "challengesEnabled is required")
        Boolean challengesEnabled
) {
}
