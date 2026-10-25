package com.zentrapay.backend.controller;

import com.zentrapay.backend.dto.common.ApiResponse;
import com.zentrapay.backend.dto.voice.VoiceDTOs.VoiceCommandRequestDTO;
import com.zentrapay.backend.dto.voice.VoiceDTOs.VoiceCommandResponseDTO;
import com.zentrapay.backend.security.AuthenticatedUser;
import com.zentrapay.backend.security.CurrentUser;
import com.zentrapay.backend.service.voice.ZVoiceService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * ZVoice AI - every spoken or typed instruction is recorded and answered.
 * <pre>
 * POST /api/zvoice/command        record an instruction, get the reply
 * GET  /api/zvoice/history        my instructions, newest first (?limit=)
 * GET  /api/zvoice/fraud-alerts   my instructions that were flagged as suspicious
 * </pre>
 */
@RestController
@RequestMapping("/api/zvoice")
@RequiredArgsConstructor
public class ZVoiceController {

    private final ZVoiceService zVoiceService;

    @PostMapping("/command")
    public ResponseEntity<ApiResponse<VoiceCommandResponseDTO>> command(
            @CurrentUser AuthenticatedUser user,
            @Valid @RequestBody VoiceCommandRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(zVoiceService.record(user.getUserId(), request), "Instruction recorded"));
    }

    @GetMapping("/history")
    public ResponseEntity<ApiResponse<List<VoiceCommandResponseDTO>>> history(
            @CurrentUser AuthenticatedUser user,
            @RequestParam(defaultValue = "100") int limit) {
        return ResponseEntity.ok(ApiResponse.success(zVoiceService.history(user.getUserId(), limit), "History retrieved"));
    }

    @GetMapping("/fraud-alerts")
    public ResponseEntity<ApiResponse<List<VoiceCommandResponseDTO>>> fraudAlerts(@CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(zVoiceService.fraudAlerts(user.getUserId()), "Voice alerts retrieved"));
    }
}
