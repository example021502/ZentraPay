package com.zentrapay.backend.controller;

import com.zentrapay.backend.dto.card.CardsDTO;
import com.zentrapay.backend.dto.card.UserCardsDTO;
import com.zentrapay.backend.service.card.CardsServices;
import com.zentrapay.backend.dto.common.ApiResponse;
import com.zentrapay.backend.security.AuthenticatedUser;
import com.zentrapay.backend.security.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Wallets & Balances - API_CONTRACT.md se3.
 * GET  /api/wallets                     -> fiat + crypto wallets for the user
 * POST /api/wallets/fiat                -> create a fiat wallet
 * POST /api/wallets/supportedCurrencies -> supported currencies (frontend contract)
 */
@RestController
@RequestMapping("/api/cards")
@RequiredArgsConstructor
public class UserCardsController {
    private final CardsServices cardsServices;
    @GetMapping("/otherCards")
    public ResponseEntity<ApiResponse<List<CardsDTO>>> otherCards(@CurrentUser AuthenticatedUser user) {
        List<CardsDTO> cards = cardsServices.otherCards();
        return ResponseEntity.ok(ApiResponse.success(cards, "UserCards retrieved"));
    }

    @GetMapping("/userCards")
    public ResponseEntity<ApiResponse<List<UserCardsDTO>>> userCards(@CurrentUser AuthenticatedUser user) {
        List<UserCardsDTO> cards = cardsServices.userCards(user.getUserId());
        return ResponseEntity.ok(ApiResponse.success(cards, "UserCards retrieved"));
    }

}
