package com.zentrapay_application.zentrapay_spring_boot_layer.modules.secure.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.secure.dto.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.secure.model.SecuritySettingsModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.secure.service.SecureService;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.AuthenticatedUser;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.CurrentUser;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * API contract §16 — {@code /api/secure}.
 */
@RestController
@RequestMapping("/api/secure")
public class SecureController {

    private final SecureService secureService;

    public SecureController(SecureService secureService) {
        this.secureService = secureService;
    }

    @GetMapping("/status")
    public ResponseEntity<ApiResponse<SecuritySettingsDTO>> getStatus(@CurrentUser AuthenticatedUser user) {
        SecuritySettingsModel settings = secureService.getSettings(user.userId());
        return ResponseEntity.ok(ApiResponse.success(SecuritySettingsDTO.from(settings), "Security status retrieved"));
    }

    @PostMapping("/biometric")
    public ResponseEntity<ApiResponse<SecuritySettingsDTO>> setBiometric(@CurrentUser AuthenticatedUser user,
                                                                           @RequestBody BiometricRequestDTO request) {
        SecuritySettingsModel settings = secureService.setBiometric(user.userId(), request.enabled(), request.type());
        return ResponseEntity.ok(ApiResponse.success(SecuritySettingsDTO.from(settings), "Biometric setting updated"));
    }

    @PostMapping("/2fa")
    public ResponseEntity<ApiResponse<SecuritySettingsDTO>> setTwoFactor(@CurrentUser AuthenticatedUser user,
                                                                           @RequestBody TwoFactorRequestDTO request) {
        SecuritySettingsModel settings = secureService.setTwoFactor(user.userId(), request.enabled(), request.method());
        return ResponseEntity.ok(ApiResponse.success(SecuritySettingsDTO.from(settings), "Two-factor authentication setting updated"));
    }

    @PostMapping("/fraud-protection")
    public ResponseEntity<ApiResponse<SecuritySettingsDTO>> setFraudProtection(@CurrentUser AuthenticatedUser user,
                                                                                 @RequestBody FraudProtectionRequestDTO request) {
        SecuritySettingsModel settings = secureService.setFraudProtection(user.userId(), request.enabled());
        return ResponseEntity.ok(ApiResponse.success(SecuritySettingsDTO.from(settings), "Fraud protection setting updated"));
    }

    @GetMapping("/fraud-alerts")
    public ResponseEntity<ApiResponse<List<FraudAlertDTO>>> getFraudAlerts(@CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(secureService.getFraudAlerts(user.userId()), "Fraud alerts retrieved"));
    }

    @GetMapping("/login-history")
    public ResponseEntity<ApiResponse<List<LoginHistoryDTO>>> getLoginHistory(@CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(secureService.getLoginHistory(user.userId()), "Login history retrieved"));
    }

    @GetMapping("/tips")
    public ResponseEntity<ApiResponse<List<SecurityTipDTO>>> getSecurityTips() {
        List<SecurityTipDTO> tips = List.of(
                new SecurityTipDTO("Use Strong Passwords", "Mix letters, numbers & symbols"),
                new SecurityTipDTO("Keep App Updated", "Latest security patches included"),
                new SecurityTipDTO("Avoid Public WiFi", "Use mobile data for transactions"),
                new SecurityTipDTO("Enable 2FA", "Double protection for your account")
        );
        return ResponseEntity.ok(ApiResponse.success(tips, "Security tips retrieved"));
    }
}
