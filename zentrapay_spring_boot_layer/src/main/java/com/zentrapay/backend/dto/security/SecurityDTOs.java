package com.zentrapay.backend.dto.security;

import jakarta.validation.constraints.NotNull;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Request / response shapes of the settings endpoints (/api/secure/*).
 */
public final class SecurityDTOs {

    private SecurityDTOs() {
    }

    /** GET /status and the response of every toggle: the user's whole settings row. */
    public record SecuritySettingsDTO(
            boolean biometricEnabled,
            String biometricType,
            boolean twoFactorEnabled,
            String twoFactorMethod,
            boolean fraudProtectionEnabled,
            boolean darkMode,
            boolean pushNotificationsEnabled,
            boolean transactionAlertsEnabled
    ) {
    }

    /** POST /biometric */
    public record BiometricRequestDTO(@NotNull(message = "Enabled flag is required") Boolean enabled, String type) {
    }

    /** POST /2fa */
    public record TwoFactorRequestDTO(@NotNull(message = "Enabled flag is required") Boolean enabled, String method) {
    }

    /** POST /fraud-protection */
    public record FraudProtectionRequestDTO(@NotNull(message = "Enabled flag is required") Boolean enabled) {
    }

    /** POST /preferences - every field optional, only the ones sent are changed. */
    public record PreferencesRequestDTO(Boolean darkMode, Boolean pushNotificationsEnabled,
                                        Boolean transactionAlertsEnabled) {
    }

    /** One row of GET /fraud-alerts. */
    public record FraudAlertDTO(UUID alertId, String alertType, String message, String severity,
                                boolean isResolved, LocalDateTime createdAt) {
    }

    /** One row of GET /login-history. */
    public record LoginHistoryDTO(UUID loginId, String ipAddress, String deviceInfo, String location,
                                  boolean success, LocalDateTime createdAt) {
    }
}
