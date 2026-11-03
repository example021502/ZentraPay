package com.zentrapay.backend.controller;

import com.zentrapay.backend.dto.common.ApiResponse;
import com.zentrapay.backend.dto.payment.SavedCardDTOs.SavedCardDTO;
import com.zentrapay.backend.security.AuthenticatedUser;
import com.zentrapay.backend.security.CurrentUser;
import com.zentrapay.backend.service.card.CardVaultService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * The cards the user chose to keep after a card top-up (tokens, never card numbers).
 *
 * <pre>
 * GET    /api/cards/saved              my saved cards (default first)
 * POST   /api/cards/saved/{id}/default make this the default card
 * DELETE /api/cards/saved/{id}         forget this card (its token is wiped)
 * </pre>
 * Cards are added by ticking "Save this card" on a top-up, and charged with POST /api/topup/card.
 */
@RestController
@RequestMapping("/api/cards/saved")
@RequiredArgsConstructor
public class SavedCardsController {

    private final CardVaultService cardVaultService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<SavedCardDTO>>> list(@CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(cardVaultService.myCards(user.getUserId()), "Saved cards retrieved"));
    }

    @PostMapping("/{cardId}/default")
    public ResponseEntity<ApiResponse<SavedCardDTO>> makeDefault(@CurrentUser AuthenticatedUser user, @PathVariable UUID cardId) {
        return ResponseEntity.ok(ApiResponse.success(cardVaultService.makeDefault(user.getUserId(), cardId), "Default card updated"));
    }

    @DeleteMapping("/{cardId}")
    public ResponseEntity<ApiResponse<Void>> remove(@CurrentUser AuthenticatedUser user, @PathVariable UUID cardId) {
        cardVaultService.remove(user.getUserId(), cardId);
        return ResponseEntity.ok(ApiResponse.success(null, "Card removed"));
    }
}
