package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payanywhere.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

/**
 * Pay Anywhere Controller
 * Scan & pay with QR, accept payments as merchant, online/offline
 */
@RestController
@RequestMapping("/api/payanywhere")
public class PayAnywhereController {

    @PostMapping("/qr/generate")
    public ResponseEntity<ApiResponse<Map<String, Object>>> generateQr(@RequestBody Map<String, Object> request) {
        System.out.println("[SPRING_CTRL] PayAnywhere generate QR hit by " + request);
        Map<String, Object> data = new HashMap<>();
        data.put("qrCode", "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==");
        data.put("qrData", "zentrapay://pay?amount=" + request.get("amount"));
        data.put("expiresAt", new Date(System.currentTimeMillis() + 300000).toString());
        return ResponseEntity.ok(ApiResponse.success(data, "QR code generated"));
    }

    @PostMapping("/qr/pay")
    public ResponseEntity<ApiResponse<Map<String, Object>>> scanAndPay(@RequestBody Map<String, Object> request) {
        System.out.println("[SPRING_CTRL] PayAnywhere scan and pay hit by " + request);
        Map<String, Object> data = new HashMap<>();
        data.put("transactionId", "payanywhere_txn_001");
        data.put("status", "completed");
        return ResponseEntity.ok(ApiResponse.success(data, "Payment successful"));
    }

    @PostMapping("/merchant/accept")
    public ResponseEntity<ApiResponse<Map<String, Object>>> merchantAccept(@RequestBody Map<String, Object> request) {
        System.out.println("[SPRING_CTRL] PayAnywhere merchant accept hit by " + request);
        Map<String, Object> data = new HashMap<>();
        data.put("transactionId", "merchant_txn_001");
        data.put("status", "completed");
        return ResponseEntity.ok(ApiResponse.success(data, "Payment received"));
    }

    @GetMapping("/merchant/stats")
    public ResponseEntity<ApiResponse<Map<String, Object>>> merchantStats() {
        System.out.println("[SPRING_CTRL] PayAnywhere merchant stats hit");
        Map<String, Object> data = new HashMap<>();
        Map<String, Object> today = new HashMap<>();
        today.put("transactions", 15);
        today.put("revenue", "GHS 450.00");
        data.put("today", today);
        return ResponseEntity.ok(ApiResponse.success(data, "Merchant stats retrieved"));
    }

    @PostMapping("/offline/pay")
    public ResponseEntity<ApiResponse<Map<String, Object>>> offlinePay(@RequestBody Map<String, Object> request) {
        System.out.println("[SPRING_CTRL] PayAnywhere offline pay hit by " + request);
        Map<String, Object> data = new HashMap<>();
        data.put("transactionId", "offline_txn_001");
        data.put("status", "pending_sync");
        return ResponseEntity.ok(ApiResponse.success(data, "Offline payment queued"));
    }

    @PostMapping("/link/create")
    public ResponseEntity<ApiResponse<Map<String, Object>>> createPaymentLink(@RequestBody Map<String, Object> request) {
        System.out.println("[SPRING_CTRL] PayAnywhere create link hit by " + request);
        Map<String, Object> data = new HashMap<>();
        data.put("linkId", "link_001");
        data.put("url", "https://zentrapay.com/pay/link_001");
        return ResponseEntity.ok(ApiResponse.success(data, "Payment link created"));
    }
}