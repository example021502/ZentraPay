package com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittance.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittance.dtos.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittance.service.RemittanceService;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.AuthenticatedUser;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.CurrentUser;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * ZRemit — API_CONTRACT.md §12.
 */
@RestController
@RequestMapping("/api/remittance")
@RequiredArgsConstructor
public class RemittanceController {

    private final RemittanceService remittanceService;

    @PostMapping("/send")
    public ResponseEntity<ApiResponse<SendResponseDTO>> send(@CurrentUser AuthenticatedUser user,
                                                              @Valid @RequestBody SendRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(remittanceService.send(user.userId(), request), "Remittance sent"));
    }

    @GetMapping("/history")
    public ResponseEntity<ApiResponse<List<RemittanceHistoryDTO>>> history(@CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(remittanceService.history(user.userId()), "Remittance history retrieved"));
    }

    @GetMapping("/rates")
    public ResponseEntity<ApiResponse<RemittanceRatesResponseDTO>> rates(@RequestParam String source,
                                                                          @RequestParam String destination) {
        return ResponseEntity.ok(ApiResponse.success(remittanceService.rates(source, destination), "Rates retrieved"));
    }
}
