package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zvoice.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

/**
 * ZVoice AI Controller
 * Full voice control, hands-free balance checks, voice fraud alerts
 */
@RestController
@RequestMapping("/api/zvoice")
public class ZVoiceController {

    @PostMapping("/command")
    public ResponseEntity<ApiResponse<Map<String, Object>>> processCommand(@RequestBody Map<String, Object> request) {
        System.out.println("[SPRING_CTRL] ZVoice command hit by " + request);
        Map<String, Object> data = new HashMap<>();
        data.put("interpreted", "check_balance");
        data.put("response", "Your current balance is GHS 3,345,456.00");
        return ResponseEntity.ok(ApiResponse.success(data, "Voice command processed"));
    }

    @GetMapping("/languages")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getLanguages() {
        System.out.println("[SPRING_CTRL] ZVoice get languages hit");
        Map<String, Object> data = new HashMap<>();
        List<Map<String, String>> languages = new ArrayList<>();
        languages.add(Map.of("code", "en", "name", "English"));
        languages.add(Map.of("code", "fr", "name", "French"));
        languages.add(Map.of("code", "sw", "name", "Swahili"));
        languages.add(Map.of("code", "tw", "name", "Twi"));
        languages.add(Map.of("code", "ha", "name", "Hausa"));
        data.put("languages", languages);
        return ResponseEntity.ok(ApiResponse.success(data, "Languages retrieved successfully"));
    }

    @GetMapping("/balance")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getVoiceBalance() {
        System.out.println("[SPRING_CTRL] ZVoice get balance hit");
        Map<String, Object> data = new HashMap<>();
        data.put("balance", "GHS 3,345,456.00");
        data.put("voiceResponse", "Your current balance is three million, three hundred forty-five thousand, four hundred fifty-six Ghana Cedis.");
        return ResponseEntity.ok(ApiResponse.success(data, "Voice balance retrieved"));
    }

    @PostMapping("/transfer")
    public ResponseEntity<ApiResponse<Map<String, Object>>> voiceTransfer(@RequestBody Map<String, Object> request) {
        System.out.println("[SPRING_CTRL] ZVoice transfer hit by " + request);
        Map<String, Object> data = new HashMap<>();
        data.put("transactionId", "zvoice_txn_001");
        data.put("status", "processing");
        return ResponseEntity.ok(ApiResponse.success(data, "Voice transfer initiated"));
    }

    @GetMapping("/fraud-alerts")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getFraudAlerts() {
        System.out.println("[SPRING_CTRL] ZVoice get fraud alerts hit");
        Map<String, Object> data = new HashMap<>();
        data.put("alerts", new ArrayList<>());
        return ResponseEntity.ok(ApiResponse.success(data, "Fraud alerts retrieved"));
    }
}