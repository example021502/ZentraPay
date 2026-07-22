package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zpay.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

/**
 * ZPay Wallet Controller
 * Multi-currency & crypto wallet, NFC/QR payments, virtual & physical cards
 */
@RestController
@RequestMapping("/api/zpay")
public class ZPayController {

    @GetMapping("/balance")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getBalance() {
        System.out.println("[SPRING_CTRL] ZPay get balance hit");
        Map<String, Object> data = new HashMap<>();
        data.put("totalBalance", "GHS 3,345,456.00");
        data.put("fiatBalance", "GHS 2,500,000.00");
        data.put("cryptoBalance", "GHS 845,456.00");
        return ResponseEntity.ok(ApiResponse.success(data, "Balance retrieved successfully"));
    }

    @GetMapping("/cards")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getCards() {
        System.out.println("[SPRING_CTRL] ZPay get cards hit");
        Map<String, Object> data = new HashMap<>();
        List<Map<String, String>> cards = new ArrayList<>();
        Map<String, String> card1 = new HashMap<>();
        card1.put("id", "card_001");
        card1.put("type", "virtual");
        card1.put("last4", "4242");
        card1.put("brand", "Visa");
        card1.put("status", "active");
        cards.add(card1);
        data.put("cards", cards);
        return ResponseEntity.ok(ApiResponse.success(data, "Cards retrieved successfully"));
    }

    @PostMapping("/payment/nfc-qr")
    public ResponseEntity<ApiResponse<Map<String, Object>>> processNfcQrPayment(@RequestBody Map<String, Object> request) {
        System.out.println("[SPRING_CTRL] ZPay NFC/QR payment hit by " + request);
        Map<String, Object> data = new HashMap<>();
        data.put("transactionId", "txn_nfc_001");
        data.put("status", "completed");
        data.put("timestamp", new Date().toString());
        return ResponseEntity.ok(ApiResponse.success(data, "Payment processed successfully"));
    }

    @GetMapping("/transactions")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getTransactions() {
        System.out.println("[SPRING_CTRL] ZPay get transactions hit");
        Map<String, Object> data = new HashMap<>();
        data.put("transactions", new ArrayList<>());
        return ResponseEntity.ok(ApiResponse.success(data, "Transactions retrieved successfully"));
    }
}