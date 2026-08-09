package com.zentrapay_application.zentrapay_spring_boot_layer.modules.secure.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.FraudAlertRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.LoginHistoryRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.secure.dto.FraudAlertDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.secure.dto.LoginHistoryDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.secure.model.SecuritySettingsModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.secure.repository.SecuritySettingsRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * API contract §16 — Security Hub: per-user biometric/2FA/fraud-protection
 * settings, plus real (no longer always-empty) fraud alerts and login history.
 */
@Service
@Transactional
public class SecureService {

    private static final Logger log = LoggerFactory.getLogger(SecureService.class);

    private final SecuritySettingsRepository securitySettingsRepository;
    private final FraudAlertRepository fraudAlertRepository;
    private final LoginHistoryRepository loginHistoryRepository;

    public SecureService(SecuritySettingsRepository securitySettingsRepository,
                          FraudAlertRepository fraudAlertRepository,
                          LoginHistoryRepository loginHistoryRepository) {
        this.securitySettingsRepository = securitySettingsRepository;
        this.fraudAlertRepository = fraudAlertRepository;
        this.loginHistoryRepository = loginHistoryRepository;
    }

    @Transactional(readOnly = true)
    public SecuritySettingsModel getSettings(UUID userId) {
        return securitySettingsRepository.findByUserId(userId)
                .orElseGet(() -> defaultSettings(userId));
    }

    public SecuritySettingsModel setBiometric(UUID userId, boolean enabled, String type) {
        log.info("[SECURE] Setting biometric for userId={}, enabled={}, type={}", userId, enabled, type);
        SecuritySettingsModel settings = getOrCreateSettings(userId);
        settings.setBiometricEnabled(enabled);
        settings.setBiometricType(type);
        return securitySettingsRepository.save(settings);
    }

    public SecuritySettingsModel setTwoFactor(UUID userId, boolean enabled, String method) {
        log.info("[SECURE] Setting 2FA for userId={}, enabled={}, method={}", userId, enabled, method);
        SecuritySettingsModel settings = getOrCreateSettings(userId);
        settings.setTwoFactorEnabled(enabled);
        settings.setTwoFactorMethod(method);
        return securitySettingsRepository.save(settings);
    }

    public SecuritySettingsModel setFraudProtection(UUID userId, boolean enabled) {
        log.info("[SECURE] Setting fraud protection for userId={}, enabled={}", userId, enabled);
        SecuritySettingsModel settings = getOrCreateSettings(userId);
        settings.setFraudProtectionEnabled(enabled);
        return securitySettingsRepository.save(settings);
    }

    @Transactional(readOnly = true)
    public List<FraudAlertDTO> getFraudAlerts(UUID userId) {
        return fraudAlertRepository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .map(FraudAlertDTO::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<LoginHistoryDTO> getLoginHistory(UUID userId) {
        return loginHistoryRepository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .map(LoginHistoryDTO::from)
                .toList();
    }

    private SecuritySettingsModel getOrCreateSettings(UUID userId) {
        return securitySettingsRepository.findByUserId(userId)
                .orElseGet(() -> securitySettingsRepository.save(defaultSettings(userId)));
    }

    private SecuritySettingsModel defaultSettings(UUID userId) {
        SecuritySettingsModel settings = new SecuritySettingsModel();
        settings.setUserId(userId);
        settings.setBiometricEnabled(false);
        settings.setTwoFactorEnabled(false);
        settings.setFraudProtectionEnabled(true);
        return settings;
    }
}
