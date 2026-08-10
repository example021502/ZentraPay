package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zvoice.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zvoice.dto.CommandRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zvoice.dto.CommandResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zvoice.dto.HistoryItemDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zvoice.dto.VoiceFraudAlertDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zvoice.model.VoiceCommandModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zvoice.service.ZVoiceService;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.AuthenticatedUser;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.CurrentUser;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * ZVoice AI (API contract §17). {@code POST /command} now takes a JSON body,
 * fixing the previous {@code @RequestParam}-only endpoint the Flutter client
 * was never actually able to call correctly.
 */
@RestController
@RequestMapping("/api/zvoice")
public class ZVoiceController {

    private final ZVoiceService zVoiceService;

    public ZVoiceController(ZVoiceService zVoiceService) {
        this.zVoiceService = zVoiceService;
    }

    @PostMapping("/command")
    public ResponseEntity<ApiResponse<CommandResponseDTO>> recordCommand(
            @CurrentUser AuthenticatedUser user,
            @RequestBody @Valid CommandRequestDTO request) {
        VoiceCommandModel command = zVoiceService.recordCommand(user.userId(), request);
        return ResponseEntity.ok(ApiResponse.success(CommandResponseDTO.from(command), "Voice command recorded"));
    }

    @GetMapping("/history")
    public ResponseEntity<ApiResponse<List<HistoryItemDTO>>> getHistory(
            @CurrentUser AuthenticatedUser user,
            @RequestParam(required = false) String language) {
        List<HistoryItemDTO> history = zVoiceService.getUserVoiceCommands(user.userId(), language).stream()
                .map(HistoryItemDTO::from)
                .toList();
        return ResponseEntity.ok(ApiResponse.success(history, "Voice history retrieved"));
    }

    @GetMapping("/fraud-alerts")
    public ResponseEntity<ApiResponse<List<VoiceFraudAlertDTO>>> getFraudAlerts(@CurrentUser AuthenticatedUser user) {
        List<VoiceFraudAlertDTO> alerts = zVoiceService.getFraudAlerts(user.userId()).stream()
                .map(VoiceFraudAlertDTO::from)
                .toList();
        return ResponseEntity.ok(ApiResponse.success(alerts, "Fraud alerts retrieved"));
    }
}
