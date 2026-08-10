package com.zentrapay_application.zentrapay_spring_boot_layer.modules.cards.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.cards.dto.CardDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.cards.dto.CardPaymentRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.cards.dto.CardPaymentResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.cards.dto.ToggleRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.cards.dto.VirtualCardRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.cards.service.CardsService;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.AuthenticatedUser;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.CurrentUser;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * API contract §4 — owns all card functionality (supersedes the old
 * {@code cards.CardsModel}/{@code zpay.CardModel} split and {@code /api/zpay/*}).
 */
@RestController
@RequestMapping("/api/cards")
@RequiredArgsConstructor
public class CardsController {

    private final CardsService cardsService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<CardDTO>>> getCards(@CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(cardsService.getUserCards(user.userId()), "Cards retrieved"));
    }

    @PostMapping("/virtual")
    public ResponseEntity<ApiResponse<CardDTO>> createVirtualCard(@CurrentUser AuthenticatedUser user,
                                                                    @RequestBody @Valid VirtualCardRequestDTO request) {
        CardDTO card = cardsService.createVirtualCard(user.userId(), request);
        return ResponseEntity.ok(ApiResponse.success(card, "Virtual card created"));
    }

    @PatchMapping("/{cardId}/nfc")
    public ResponseEntity<ApiResponse<CardDTO>> toggleNfc(@CurrentUser AuthenticatedUser user,
                                                            @PathVariable UUID cardId,
                                                            @RequestBody ToggleRequestDTO request) {
        CardDTO card = cardsService.setNfcEnabled(user.userId(), cardId, request.enabled());
        return ResponseEntity.ok(ApiResponse.success(card, "NFC setting updated"));
    }

    @PatchMapping("/{cardId}/qr")
    public ResponseEntity<ApiResponse<CardDTO>> toggleQr(@CurrentUser AuthenticatedUser user,
                                                           @PathVariable UUID cardId,
                                                           @RequestBody ToggleRequestDTO request) {
        CardDTO card = cardsService.setQrEnabled(user.userId(), cardId, request.enabled());
        return ResponseEntity.ok(ApiResponse.success(card, "QR setting updated"));
    }

    @PostMapping("/{cardId}/pay")
    public ResponseEntity<ApiResponse<CardPaymentResponseDTO>> payWithCard(@CurrentUser AuthenticatedUser user,
                                                                             @PathVariable UUID cardId,
                                                                             @RequestBody @Valid CardPaymentRequestDTO request) {
        CardPaymentResponseDTO response = cardsService.payWithCard(user.userId(), cardId, request);
        return ResponseEntity.ok(ApiResponse.success(response, "Card payment processed"));
    }
}
