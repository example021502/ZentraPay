package com.zentrapay.backend.controller;

import com.zentrapay.backend.dto.common.ApiResponse;
import com.zentrapay.backend.dto.security.SecurityDTOs.*;
import com.zentrapay.backend.security.AuthenticatedUser;
import com.zentrapay.backend.security.CurrentUser;
import com.zentrapay.backend.service.security.SecurityService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Settings - security toggles, preferences, login history and fraud alerts.
 * <pre>
 * GET  /api/secure/status            my settings
 * POST /api/secure/biometric         turn biometric login on / off
 * POST /api/secure/2fa               turn two-factor on / off
 * POST /api/secure/fraud-protection  turn fraud protection on / off
 * POST /api/secure/preferences       dark mode, notification switches
 * GET  /api/secure/login-history     my recent sign-ins
 * GET  /api/secure/fraud-alerts      my fraud alerts
 * </pre>
 * Every POST returns the full, updated settings.
 */
@RestController
@RequestMapping("/api/secure")
@RequiredArgsConstructor
public class SecurityController {

    private final SecurityService securityService;

    @GetMapping("/status")
    public ResponseEntity<ApiResponse<SecuritySettingsDTO>> status(@CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(securityService.getSettings(user.getUserId()), "Settings retrieved"));
    }

    @PostMapping("/biometric")
    public ResponseEntity<ApiResponse<SecuritySettingsDTO>> biometric(
            @CurrentUser AuthenticatedUser user, @Valid @RequestBody BiometricRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(securityService.setBiometric(user.getUserId(), request), "Settings updated"));
    }

    @PostMapping("/2fa")
    public ResponseEntity<ApiResponse<SecuritySettingsDTO>> twoFactor(
            @CurrentUser AuthenticatedUser user, @Valid @RequestBody TwoFactorRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(securityService.setTwoFactor(user.getUserId(), request), "Settings updated"));
    }

    @PostMapping("/fraud-protection")
    public ResponseEntity<ApiResponse<SecuritySettingsDTO>> fraudProtection(
            @CurrentUser AuthenticatedUser user, @Valid @RequestBody FraudProtectionRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(securityService.setFraudProtection(user.getUserId(), request), "Settings updated"));
    }

    @PostMapping("/preferences")
    public ResponseEntity<ApiResponse<SecuritySettingsDTO>> preferences(
            @CurrentUser AuthenticatedUser user, @RequestBody PreferencesRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(securityService.updatePreferences(user.getUserId(), request), "Settings updated"));
    }

    @GetMapping("/login-history")
    public ResponseEntity<ApiResponse<List<LoginHistoryDTO>>> loginHistory(@CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(securityService.loginHistory(user.getUserId()), "Login history retrieved"));
    }

    @GetMapping("/fraud-alerts")
    public ResponseEntity<ApiResponse<List<FraudAlertDTO>>> fraudAlerts(@CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(securityService.fraudAlerts(user.getUserId()), "Fraud alerts retrieved"));
    }
}
