package com.zentrapay_application.zentrapay_spring_boot_layer.modules.Cards.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.Cards.dtos.UserCardsDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.Cards.services.CardsServices;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.AuthenticatedUser;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.CurrentUser;
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
@RequestMapping("/api/zbanking")
@RequiredArgsConstructor
public class userCardsController {

    private CardsServices cardsServices;

    @GetMapping("/userCards")
    public ResponseEntity<ApiResponse<List<UserCardsDTO>>> userCards(@CurrentUser AuthenticatedUser user) {
        List<UserCardsDTO> cards = cardsServices.userCards(user.getUserId());
        return ResponseEntity.ok(ApiResponse.success(cards, "UserCards retrieved"));
    }

}
