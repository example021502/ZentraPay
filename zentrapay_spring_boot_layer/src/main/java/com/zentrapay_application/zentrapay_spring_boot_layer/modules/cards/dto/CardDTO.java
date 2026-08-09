package com.zentrapay_application.zentrapay_spring_boot_layer.modules.cards.dto;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.Card;

import java.util.UUID;

/**
 * API contract §4 card shape:
 * {@code {cardId,brand,cardType,last4,expiryMonth,expiryYear,nfcEnabled,qrEnabled,status}}.
 */
public record CardDTO(
        UUID cardId,
        String brand,
        String cardType,
        String last4,
        short expiryMonth,
        short expiryYear,
        boolean nfcEnabled,
        boolean qrEnabled,
        String status
) {
    public static CardDTO from(Card card) {
        return new CardDTO(
                card.getCardId(),
                card.getBrand(),
                card.getCardType(),
                card.getLast4(),
                card.getExpiryMonth(),
                card.getExpiryYear(),
                card.isNfcEnabled(),
                card.isQrEnabled(),
                card.getStatus()
        );
    }
}
