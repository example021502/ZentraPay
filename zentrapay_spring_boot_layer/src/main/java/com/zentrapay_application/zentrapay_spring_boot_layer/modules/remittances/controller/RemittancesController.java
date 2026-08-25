package com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittances.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittances.dtos.RemitQuoteResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittances.dtos.RemitRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittances.dtos.RemitResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittances.service.RemittancesService;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.AuthenticatedUser;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.CurrentUser;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * Cross-border remittances — ZRemit.
 * <p>
 * POST /api/remittance/send     -> send money to a recipient in ANOTHER country
 *                                  (same-country recipients are rejected with an
 *                                  explicit message; domestic belongs to /api/payments)
 * GET  /api/remittance/history  -> the caller's past sends
 * GET  /api/remittance/rates    -> FX preview (?source=GHS&destination=NGN[&amount=])
 */
@RestController
@RequestMapping("/api/remittance")
@RequiredArgsConstructor
public class RemittancesController {

    private final RemittancesService remittancesService;

    @PostMapping("/send")
    public ResponseEntity<ApiResponse<Map<String, Object>>> send(
            @CurrentUser AuthenticatedUser user,
            @Valid @RequestBody RemitRequestDTO request) {
        RemitResponseDTO remittance = remittancesService.send(user.getUserId(), request);
        // Wrapped under "remittance" — the frontend prepends exactly this object
        // into its cached history list right after a successful send.
        return ResponseEntity.ok(ApiResponse.success(Map.of("remittance", remittance), "Remittance initiated successfully"));
    }

    @GetMapping("/history")
    public ResponseEntity<ApiResponse<List<RemitResponseDTO>>> history(@CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(remittancesService.history(user.getUserId()), "Remittance history retrieved"));
    }

    @GetMapping("/rates")
    public ResponseEntity<ApiResponse<RemitQuoteResponseDTO>> rates(
            @RequestParam String source,
            @RequestParam String destination,
            @RequestParam(required = false) BigDecimal amount) {
        return ResponseEntity.ok(ApiResponse.success(
                remittancesService.rates(source, destination, amount), "Exchange rate retrieved"));
    }
}