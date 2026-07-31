package com.zentrapay_application.zentrapay_spring_boot_layer.modules.history.Controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.history.dtos.HistoryResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.history.services.HistoryServices;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/history")
@RequiredArgsConstructor
public class HistoryController {

    private final HistoryServices historyServices;

    @GetMapping("/paymentsHistory")
    public ResponseEntity<ApiResponse<HistoryResponseDTO>> getPaymentsHistory(Authentication authentication) {
        UUID userId = UUID.fromString(authentication.getName());
        HistoryResponseDTO history = historyServices.getPaymentsHistory(userId);
        return ResponseEntity.ok(ApiResponse.success(history, "Payment history retrieved"));
    }
}
