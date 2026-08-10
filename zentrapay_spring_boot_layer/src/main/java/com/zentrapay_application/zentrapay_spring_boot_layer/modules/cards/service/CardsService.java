package com.zentrapay_application.zentrapay_spring_boot_layer.modules.cards.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ResourceNotFoundException;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.Card;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.Transaction;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.Wallet;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.CardRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.TransactionRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.WalletRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.cards.dto.CardDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.cards.dto.CardPaymentRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.cards.dto.CardPaymentResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.cards.dto.VirtualCardRequestDTO;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Owns all card functionality — consolidates the old {@code cards.CardsModel} /
 * {@code zpay.CardModel} split (API contract §4), including virtual card
 * creation and NFC/QR toggling/payment that used to live in the now-deleted
 * {@code zpay} module.
 */
@Service
@RequiredArgsConstructor
@Transactional
public class CardsService {

    private static final Logger log = LoggerFactory.getLogger(CardsService.class);
    private static final SecureRandom RANDOM = new SecureRandom();

    private final CardRepository cardRepository;
    private final WalletRepository walletRepository;
    private final TransactionRepository transactionRepository;

    @Transactional(readOnly = true)
    public List<CardDTO> getUserCards(UUID userId) {
        return cardRepository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .map(CardDTO::from)
                .toList();
    }

    public CardDTO createVirtualCard(UUID userId, VirtualCardRequestDTO request) {
        Card card = new Card();
        card.setUserId(userId);
        card.setBrand(request.brand());
        card.setCardType("VIRTUAL");
        card.setLast4(String.format("%04d", RANDOM.nextInt(10000)));

        LocalDate expiry = LocalDate.now().plusYears(3);
        card.setExpiryMonth((short) expiry.getMonthValue());
        card.setExpiryYear((short) expiry.getYear());
        card.setNfcEnabled(true);
        card.setQrEnabled(true);
        card.setStatus("ACTIVE");

        // Link to the user's default wallet, if one exists, so card payments have
        // somewhere to debit from immediately.
        final Card newCard = card;
        walletRepository.findByUserIdAndIsDefaultTrue(userId)
                .ifPresent(wallet -> newCard.setWalletId(wallet.getWalletId()));

        card = cardRepository.save(card);
        log.info("[CARDS] Virtual card created: cardId={}, userId={}, brand={}", card.getCardId(), userId, request.brand());
        return CardDTO.from(card);
    }

    public CardDTO setNfcEnabled(UUID userId, UUID cardId, boolean enabled) {
        Card card = getOwnedCard(userId, cardId);
        card.setNfcEnabled(enabled);
        return CardDTO.from(cardRepository.save(card));
    }

    public CardDTO setQrEnabled(UUID userId, UUID cardId, boolean enabled) {
        Card card = getOwnedCard(userId, cardId);
        card.setQrEnabled(enabled);
        return CardDTO.from(cardRepository.save(card));
    }

    public CardPaymentResponseDTO payWithCard(UUID userId, UUID cardId, CardPaymentRequestDTO request) {
        Card card = getOwnedCard(userId, cardId);

        if (!"ACTIVE".equals(card.getStatus())) {
            throw new RuntimeException("Card is not active");
        }

        String method = request.method() == null ? "" : request.method().toUpperCase();
        if ("NFC".equals(method) && !card.isNfcEnabled()) {
            throw new RuntimeException("NFC is disabled for this card");
        } else if ("QR".equals(method) && !card.isQrEnabled()) {
            throw new RuntimeException("QR is disabled for this card");
        } else if (!"NFC".equals(method) && !"QR".equals(method)) {
            throw new RuntimeException("Unsupported payment method: " + request.method());
        }

        if (card.getWalletId() == null) {
            throw new RuntimeException("Card has no linked wallet");
        }

        Wallet wallet = walletRepository.findById(card.getWalletId())
                .orElseThrow(() -> new ResourceNotFoundException("Linked wallet not found"));

        if (!wallet.getCurrencyCode().equalsIgnoreCase(request.currencyCode())) {
            throw new RuntimeException("Currency mismatch: card's wallet is in " + wallet.getCurrencyCode());
        }

        int debited = walletRepository.debit(wallet.getWalletId(), request.amount());
        if (debited == 0) {
            throw new RuntimeException("Insufficient balance");
        }

        Transaction transaction = new Transaction();
        transaction.setUserId(userId);
        transaction.setWalletId(wallet.getWalletId());
        transaction.setTypeCode("CARD_PAYMENT");
        transaction.setAmount(request.amount());
        transaction.setCurrencyCode(request.currencyCode());
        transaction.setStatus("SUCCESS");
        transaction.setGateway("ZentraPayCard");
        transaction.setReference("CARD-" + UUID.randomUUID());
        transaction.setCounterpartyName(request.merchantName());
        transaction.setDescription(method + " card payment at " + request.merchantName());
        transaction = transactionRepository.save(transaction);

        log.info("[CARDS] Card payment successful: cardId={}, transactionId={}, amount={} {}",
                cardId, transaction.getTransactionId(), request.amount(), request.currencyCode());

        return new CardPaymentResponseDTO(transaction.getTransactionId(), transaction.getStatus());
    }

    private Card getOwnedCard(UUID userId, UUID cardId) {
        return cardRepository.findByCardIdAndUserId(cardId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Card not found"));
    }
}
