package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto;

/** Persisted ZGrow toggle state: GET/PUT /api/zgrow/gamification shape. */
public record GamificationSettingsDTO(
        Boolean challengesEnabled
) {
}
