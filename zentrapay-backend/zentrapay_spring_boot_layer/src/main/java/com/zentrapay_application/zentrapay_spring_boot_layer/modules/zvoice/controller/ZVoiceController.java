package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zvoice.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zvoice.model.VoiceCommandModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zvoice.service.ZVoiceService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.Authentication;

import java.util.List;
import java.util.UUID;

/**
 * ZVoice AI Controller - Full voice control, hands-free balance checks, voice fraud alerts
 */
@RestController
@RequestMapping("/api/zvoice")
public class ZVoiceController {

    private final ZVoiceService zVoiceService;

    public ZVoiceController(ZVoiceService zVoiceService) {
        this.zVoiceService = zVoiceService;
    }

    /**
     * Record a voice command.
     */
    @PostMapping("/command")
    public ResponseEntity<ApiResponse<Object>> recordCommand(
            Authentication authentication,
            @RequestParam String commandType,
            @RequestParam String language,
            @RequestParam String transcript,
            @RequestParam(defaultValue = "false") boolean fraudAlert,
            @RequestParam(required = false) String fraudReason) {
        UUID userId = UUID.fromString(authentication.getName());
        return ResponseEntity.ok(ApiResponse.success(
                zVoiceService.recordVoiceCommand(userId, commandType, language, transcript, fraudAlert, fraudReason),
                "Voice command recorded"));
    }

    /**
     * Get user's voice command history.
     */
    @GetMapping("/history")
    public ResponseEntity<ApiResponse<List<VoiceCommandModel>>> getHistory(Authentication authentication) {
        UUID userId = UUID.fromString(authentication.getName());
        return ResponseEntity.ok(ApiResponse.success(
                zVoiceService.getUserVoiceCommands(userId),
                "Voice history retrieved"));
    }

    /**
     * Get fraud alerts.
     */
    @GetMapping("/fraud-alerts")
    public ResponseEntity<ApiResponse<List<VoiceCommandModel>>> getFraudAlerts(Authentication authentication) {
        UUID userId = UUID.fromString(authentication.getName());
        return ResponseEntity.ok(ApiResponse.success(
                zVoiceService.getFraudAlerts(userId),
                "Fraud alerts retrieved"));
    }

    /**
     * Get commands by language.
     */
    @GetMapping("/language/{language}")
    public ResponseEntity<ApiResponse<List<VoiceCommandModel>>> getCommandsByLanguage(
            Authentication authentication,
            @PathVariable String language) {
        UUID userId = UUID.fromString(authentication.getName());
        return ResponseEntity.ok(ApiResponse.success(
                zVoiceService.getCommandsByLanguage(userId, language),
                "Commands by language retrieved"));
    }
}
