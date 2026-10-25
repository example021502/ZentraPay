package com.zentrapay.backend.service.security;

import com.zentrapay.backend.dto.security.SecurityDTOs.*;
import com.zentrapay.backend.entity.SecuritySettingsModel;
import com.zentrapay.backend.repository.FraudAlertRepository;
import com.zentrapay.backend.repository.LoginHistoryRepository;
import com.zentrapay.backend.repository.SecuritySettingsRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * The Settings screen: the user's security toggles and preferences, their login
 * history and fraud alerts. Every toggle is saved immediately and the full,
 * updated settings row is returned so the app can mirror exactly what is stored.
 */
@Service
@RequiredArgsConstructor
public class SecurityService {

    private static final Set<String> BIOMETRIC_TYPES = Set.of("FINGERPRINT", "FACE", "IRIS");
    private static final Set<String> TWO_FACTOR_METHODS = Set.of("SMS", "EMAIL", "AUTHENTICATOR");

    private final SecuritySettingsRepository settingsRepository;
    private final LoginHistoryRepository loginHistoryRepository;
    private final FraudAlertRepository fraudAlertRepository;

    /** The user's settings; a user who never opened Settings gets a default row. */
    @Transactional
    public SecuritySettingsDTO getSettings(UUID userId) {
        return toDTO(settingsFor(userId));
    }

    @Transactional
    public SecuritySettingsDTO setBiometric(UUID userId, BiometricRequestDTO request) {
        SecuritySettingsModel settings = settingsFor(userId);
        settings.setBiometricEnabled(request.enabled());
        if (request.enabled()) {
            settings.setBiometricType(oneOf(request.type(), BIOMETRIC_TYPES, "FINGERPRINT"));
        }
        return toDTO(settingsRepository.save(settings));
    }

    @Transactional
    public SecuritySettingsDTO setTwoFactor(UUID userId, TwoFactorRequestDTO request) {
        SecuritySettingsModel settings = settingsFor(userId);
        settings.setTwoFactorEnabled(request.enabled());
        if (request.enabled()) {
            settings.setTwoFactorMethod(oneOf(request.method(), TWO_FACTOR_METHODS, "SMS"));
        }
        return toDTO(settingsRepository.save(settings));
    }

    @Transactional
    public SecuritySettingsDTO setFraudProtection(UUID userId, FraudProtectionRequestDTO request) {
        SecuritySettingsModel settings = settingsFor(userId);
        settings.setFraudProtectionEnabled(request.enabled());
        return toDTO(settingsRepository.save(settings));
    }

    /** Dark mode and notification switches. Fields left null are not touched. */
    @Transactional
    public SecuritySettingsDTO updatePreferences(UUID userId, PreferencesRequestDTO request) {
        SecuritySettingsModel settings = settingsFor(userId);
        if (request.darkMode() != null) {
            settings.setDarkMode(request.darkMode());
        }
        if (request.pushNotificationsEnabled() != null) {
            settings.setPushNotificationsEnabled(request.pushNotificationsEnabled());
        }
        if (request.transactionAlertsEnabled() != null) {
            settings.setTransactionAlertsEnabled(request.transactionAlertsEnabled());
        }
        return toDTO(settingsRepository.save(settings));
    }

    @Transactional(readOnly = true)
    public List<LoginHistoryDTO> loginHistory(UUID userId) {
        return loginHistoryRepository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .limit(50)
                .map(h -> new LoginHistoryDTO(h.getLoginId(), h.getIpAddress(), h.getDeviceInfo(),
                        h.getLocation(), h.isSuccess(), h.getCreatedAt()))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<FraudAlertDTO> fraudAlerts(UUID userId) {
        return fraudAlertRepository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .map(a -> new FraudAlertDTO(a.getAlertId(), a.getAlertType(), a.getMessage(),
                        a.getSeverity(), a.isResolved(), a.getCreatedAt()))
                .toList();
    }

    private SecuritySettingsModel settingsFor(UUID userId) {
        return settingsRepository.findByUserId(userId).orElseGet(() -> {
            SecuritySettingsModel created = new SecuritySettingsModel();
            created.setUserId(userId);
            return settingsRepository.save(created);
        });
    }

    private static String oneOf(String value, Set<String> allowed, String fallback) {
        if (value == null) {
            return fallback;
        }
        String normalised = value.trim().toUpperCase();
        return allowed.contains(normalised) ? normalised : fallback;
    }

    private static SecuritySettingsDTO toDTO(SecuritySettingsModel s) {
        return new SecuritySettingsDTO(s.isBiometricEnabled(), s.getBiometricType(), s.isTwoFactorEnabled(),
                s.getTwoFactorMethod(), s.isFraudProtectionEnabled(), s.isDarkMode(),
                s.isPushNotificationsEnabled(), s.isTransactionAlertsEnabled());
    }
}
