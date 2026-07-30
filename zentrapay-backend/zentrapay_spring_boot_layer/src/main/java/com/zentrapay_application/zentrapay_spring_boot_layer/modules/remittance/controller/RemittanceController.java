package com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittance.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittance.service.ZRemitService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * ZRemit Controller - Instant cross-border transfers, smart currency conversion
 */
@RestController
@RequestMapping("/api/remittance")
public class ZRemitController {

    private final ZRemitService zRemitService;

    public ZRemitController(ZRemitService zRemitService) {
        this.zRemitService = zRemitService;
    }

    /**
     * Create a cross-border remittance.
     */
    @PostMapping("/transfer")
    public ResponseEntity<ApiResponse<Object>> sendMoney(
            Authentication authentication,
            @RequestParam UUID receiverId,
            @RequestParam BigDecimal amount,
            @RequestParam String sourceCurrency,
            @RequestParam String destinationCurrency,
            @RequestParam String channel,
            @RequestParam String recipientPhoneNumber,
            @RequestParam String recipientName) {
        UUID senderId = UUID.fromString(authentication.getName());
        return ResponseEntity.ok(ApiResponse.success(
                zRemitService.createRemittance(senderId, receiverId, amount, sourceCurrency,
                        destinationCurrency, channel, recipientPhoneNumber, recipientName),
                "Remittance created successfully"));
    }

    /**
     * Get user's remittance history.
     */
    @GetMapping("/history")
    public ResponseEntity<ApiResponse<List<?>>> getHistory(Authentication authentication) {
        UUID userId = UUID.fromString(authentication.getName());
        return ResponseEntity.ok(ApiResponse.success(
                zRemitService.getUserRemittances(userId),
                "Remittance history retrieved"));
    }

    /**
     * Get currency exchange rates.
     */
    @GetMapping("/rates")
    public ResponseEntity<ApiResponse<Object>> getRates() {
        // TODO: Integrate with forex API
        return ResponseEntity.ok(ApiResponse.success(null, "Exchange rates retrieved"));
    }

    /**
     * Get supported countries and currencies.
     */
    @GetMapping("/supported")
    public ResponseEntity<ApiResponse<Object>> getSupported() {
        // TODO: Return list of supported countries/currencies
        return ResponseEntity.ok(ApiResponse.success(null, "Supported regions retrieved"));
    }
}