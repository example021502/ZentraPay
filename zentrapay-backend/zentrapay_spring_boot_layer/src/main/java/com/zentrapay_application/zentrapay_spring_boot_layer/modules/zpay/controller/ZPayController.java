package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zpay.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zpay.model.CardModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zpay.service.ZPayService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * ZPay Controller - Multi-currency wallet, NFC/QR payments, virtual & physical cards
 */
@RestController
@RequestMapping("/api/zpay")
public class ZPayController {

    private final ZPayService zPayService;

    public ZPayController(ZPayService zPayService) {
        this.zPayService = zPayService;
    }

    /**
     * Get user's wallet balance.
     */
    @GetMapping("/balance")
    public ResponseEntity<ApiResponse<Object>> getBalance(Authentication authentication) {
        UUID userId = UUID.fromString(authentication.getName());
        // TODO: Calculate balance from walletBalances module
        return ResponseEntity.ok(ApiResponse.success(null, "Balance retrieved"));
    }

    /**
     * Get all cards for the authenticated user.
     */
    @GetMapping("/cards")
    public ResponseEntity<ApiResponse<List<CardModel>>> getCards(Authentication authentication) {
        UUID userId = UUID.fromString(authentication.getName());
        List<CardModel> cards = zPayService.getUserCards(userId);
        return ResponseEntity.ok(ApiResponse.success(cards, "Cards retrieved successfully"));
    }

    /**
     * Create a new virtual card.
     */
    @PostMapping("/cards/virtual")
    public ResponseEntity<ApiResponse<CardModel>> createVirtualCard(
            Authentication authentication,
            @RequestParam String brand) {
        UUID userId = UUID.fromString(authentication.getName());
        CardModel card = zPayService.createVirtualCard(userId, brand);
        return ResponseEntity.ok(ApiResponse.success(card, "Virtual card created successfully"));
    }

    /**
     * Process NFC/QR payment.
     */
    @PostMapping("/payment/nfc-qr")
    public ResponseEntity<ApiResponse<Object>> processNfcQrPayment(
            Authentication authentication,
            @RequestBody Map<String, Object> request) {
        UUID userId = UUID.fromString(authentication.getName());
        // TODO: Implement NFC/QR payment processing
        return ResponseEntity.ok(ApiResponse.success(null, "Payment processed successfully"));
    }

    /**
     * Get transaction history.
     */
    @GetMapping("/transactions")
    public ResponseEntity<ApiResponse<Object>> getTransactions(Authentication authentication) {
        UUID userId = UUID.fromString(authentication.getName());
        // TODO: Retrieve transaction history from transactions table
        return ResponseEntity.ok(ApiResponse.success(null, "Transactions retrieved"));
    }

    /**
     * Toggle NFC payment for a card.
     */
    @PatchMapping("/cards/{cardId}/nfc")
    public ResponseEntity<ApiResponse<CardModel>> toggleNfc(
            @PathVariable UUID cardId,
            @RequestParam boolean enabled) {
        CardModel card = zPayService.toggleNfc(cardId, enabled);
        return ResponseEntity.ok(ApiResponse.success(card, "NFC toggled successfully"));
    }

    /**
     * Toggle QR payment for a card.
     */
    @PatchMapping("/cards/{cardId}/qr")
    public ResponseEntity<ApiResponse<CardModel>> toggleQr(
            @PathVariable UUID cardId,
            @RequestParam boolean enabled) {
        CardModel card = zPayService.toggleQr(cardId, enabled);
        return ResponseEntity.ok(ApiResponse.success(card, "QR toggled successfully"));
    }
}