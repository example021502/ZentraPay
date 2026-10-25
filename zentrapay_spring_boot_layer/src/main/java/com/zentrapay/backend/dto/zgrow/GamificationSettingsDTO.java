package com.zentrapay.backend.dto.zgrow;

/** Persisted ZGrow toggle state: GET/PUT /api/zgrow/gamification shape. */
public record GamificationSettingsDTO(
        Boolean challengesEnabled
) {
}
