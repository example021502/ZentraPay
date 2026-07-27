package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zpay.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zpay.model.CardModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zpay.repository.CardRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * Service for ZPay Wallet features: multi-currency wallet, NFC/QR payments, virtual & physical cards.
 */
@Service
@Transactional
public class ZPayService {

    private static final Logger log = LoggerFactory.getLogger(ZPayService.class);

    private final CardRepository cardRepository;

    public ZPayService(CardRepository cardRepository) {
        this.cardRepository = cardRepository;
    }

    /**
     * Retrieves all cards for a user.
     */
    @Transactional(readOnly = true)
    public List<CardModel> getUserCards(UUID userId) {
        log.info("[ZPAY] Fetching cards for userId={}", userId);
        return cardRepository.findByUserId(userId);
    }

    /**
     * Creates a new virtual card for a user.
     */
    public CardModel createVirtualCard(UUID userId, String brand) {
        log.info("[ZPAY] Creating virtual card for userId={}, brand={}", userId, brand);

        CardModel card = new CardModel();
        card.setUserId(userId);
        card.setType("virtual");
        card.setBrand(brand);
        card.setLast4(generateRandomLast4());
        card.setStatus("ACTIVE");
        card.setExpiryMonth(generateRandomMonth());
        card.setExpiryYear(generateRandomYear());
        card.setNfcEnabled(true);
        card.setQrEnabled(true);

        return cardRepository.save(card);
    }

    /**
     * Toggles NFC payment for a card.
     */
    public CardModel toggleNfc(UUID cardId, boolean enabled) {
        log.info("[ZPAY] Toggling NFC for cardId={}, enabled={}", cardId, enabled);

        CardModel card = cardRepository.findById(cardId)
                .orElseThrow(() -> new RuntimeException("Card not found"));

        card.setNfcEnabled(enabled);
        return cardRepository.save(card);
    }

    /**
     * Toggles QR payment for a card.
     */
    public CardModel toggleQr(UUID cardId, boolean enabled) {
        log.info("[ZPAY] Toggling QR for cardId={}, enabled={}", cardId, enabled);

        CardModel card = cardRepository.findById(cardId)
                .orElseThrow(() -> new RuntimeException("Card not found"));

        card.setQrEnabled(enabled);
        return cardRepository.save(card);
    }

    private String generateRandomLast4() {
        return String.valueOf((int) (Math.random() * 10000));
    }

    private int generateRandomMonth() {
        return 1 + (int) (Math.random() * 12);
    }

    private int generateRandomYear() {
        return java.time.Year.now().getValue() + 3 + (int) (Math.random() * 4);
    }
}