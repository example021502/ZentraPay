package com.zentrapay_application.zentrapay_spring_boot_layer.modules.secure.dto;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.secure.model.SecuritySettingsModel;

/**
 * API contract §16 — {@code GET /api/secure/status} and every settings-update
 * response share this shape.
 */
public record SecuritySettingsDTO(
        boolean biometricEnabled,
        String biometricType,
        boolean twoFactorEnabled,
        String twoFactorMethod,
        boolean fraudProtectionEnabled
) {
    public static SecuritySettingsDTO from(SecuritySettingsModel settings) {
        return new SecuritySettingsDTO(
                settings.isBiometricEnabled(),
                settings.getBiometricType(),
                settings.isTwoFactorEnabled(),
                settings.getTwoFactorMethod(),
                settings.isFraudProtectionEnabled()
        );
    }
}
