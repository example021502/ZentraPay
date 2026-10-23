package com.zentrapay.backend.dto.card;

import java.util.List;

/**
 * Top-level payload returned by GET /api/wallets - matches the frontend
 * WalletsSnapshot / API_CONTRACT.md se3: {fiatWallets:[...], cryptoWallets:[...]}.
 */
public record AllCardsDTO(
    List<CardsDTO> cards,
    List<UserCardsDTO> userCards
) {
}