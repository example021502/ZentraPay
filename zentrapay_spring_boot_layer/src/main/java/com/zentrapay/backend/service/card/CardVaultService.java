package com.zentrapay.backend.service.card;

import com.zentrapay.backend.dto.payment.GatewayCardToken;
import com.zentrapay.backend.dto.payment.GatewayChargeStatus;
import com.zentrapay.backend.dto.payment.SavedCardDTOs.SavedCardDTO;
import com.zentrapay.backend.entity.GatewayModel;
import com.zentrapay.backend.entity.SavedCardModel;
import com.zentrapay.backend.entity.TransactionModel;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.repository.SavedCardRepository;
import com.zentrapay.backend.service.common.Datatypes;
import com.zentrapay.backend.service.gateway.FlutterwaveServices;
import com.zentrapay.backend.service.gateway.GatewayServices;
import com.zentrapay.backend.service.gateway.PaystackServices;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.Base64;
import java.util.List;
import java.util.UUID;

/**
 * Card tokenization: keeps the reusable token a gateway returns after a card payment, and hands it back
 * (decrypted) only to the code that charges the card.
 *
 * <p>Nothing here ever sees a card number or CVV - the customer types those into the gateway's own checkout
 * (Paystack SDK / Flutterwave hosted page). We store the gateway token, AES-256-GCM encrypted with a key
 * derived from the server secret, together with the receipt details (last 4, brand, expiry, bank).
 *
 * <p>A card is saved only when the user ticked "Save this card" on the top-up that paid with it
 * (recorded in that transaction's metadata as {@code saveCard=true}).
 */
@Slf4j
@Service
public class CardVaultService {

    private static final SecureRandom RANDOM = new SecureRandom();
    /** Stops a user from piling up cards. */
    private static final int MAX_CARDS = 10;

    private final SavedCardRepository savedCardRepository;
    private final GatewayServices gatewayServices;
    private final PaystackServices paystackServices;
    private final FlutterwaveServices flutterwaveServices;
    private final SecretKeySpec key;

    public CardVaultService(SavedCardRepository savedCardRepository, GatewayServices gatewayServices,
                            PaystackServices paystackServices, FlutterwaveServices flutterwaveServices,
                            @Value("${app.jwt.secret}") String secret) {
        this.savedCardRepository = savedCardRepository;
        this.gatewayServices = gatewayServices;
        this.paystackServices = paystackServices;
        this.flutterwaveServices = flutterwaveServices;
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(("zentrapay-saved-card|" + secret).getBytes(StandardCharsets.UTF_8));
            this.key = new SecretKeySpec(digest, "AES");
        } catch (Exception e) {
            throw new IllegalStateException("Could not initialise the card vault", e);
        }
    }

    // ------------------------------------------------------------------
    // Reading / managing
    // ------------------------------------------------------------------

    @Transactional(readOnly = true)
    public List<SavedCardDTO> myCards(UUID userId) {
        return savedCardRepository.findByUserIdAndStatusOrderByIsDefaultDescCreatedAtDesc(userId, "ACTIVE").stream()
                .map(CardVaultService::toDto)
                .toList();
    }

    /** One of the user's active cards, or "not found" (same answer for someone else's card). */
    @Transactional(readOnly = true)
    public SavedCardModel activeCard(UUID userId, UUID cardId) {
        return savedCardRepository.findByIdAndUserId(cardId, userId)
                .filter(c -> "ACTIVE".equals(c.getStatus()))
                .orElseThrow(() -> new ResourceNotFoundException("Card not found"));
    }

    @Transactional
    public SavedCardDTO makeDefault(UUID userId, UUID cardId) {
        SavedCardModel card = activeCard(userId, cardId);
        for (SavedCardModel other : savedCardRepository.findByUserIdAndStatusOrderByIsDefaultDescCreatedAtDesc(userId, "ACTIVE")) {
            boolean shouldBeDefault = other.getId().equals(card.getId());
            if (Boolean.TRUE.equals(other.getIsDefault()) != shouldBeDefault) {
                other.setIsDefault(shouldBeDefault);
                savedCardRepository.save(other);
            }
        }
        return toDto(savedCardRepository.findById(card.getId()).orElse(card));
    }

    /** Forgets the card: its token is wiped, so it can never be charged again. */
    @Transactional
    public void remove(UUID userId, UUID cardId) {
        SavedCardModel card = activeCard(userId, cardId);
        boolean wasDefault = Boolean.TRUE.equals(card.getIsDefault());
        card.setStatus("REMOVED");
        card.setIsDefault(false);
        card.setTokenEncrypted("");
        savedCardRepository.save(card);
        if (wasDefault) {
            savedCardRepository.findByUserIdAndStatusOrderByIsDefaultDescCreatedAtDesc(userId, "ACTIVE").stream()
                    .findFirst()
                    .ifPresent(next -> {
                        next.setIsDefault(true);
                        savedCardRepository.save(next);
                    });
        }
    }

    @Transactional
    public void markUsed(UUID cardId) {
        savedCardRepository.findById(cardId).ifPresent(c -> {
            c.setLastUsedAt(LocalDateTime.now());
            savedCardRepository.save(c);
        });
    }

    // ------------------------------------------------------------------
    // Saving (after a paid checkout)
    // ------------------------------------------------------------------

    /**
     * Called once a top-up has been credited: if the user asked to keep the card they paid with, asks the
     * gateway for the card's token and stores it. Never throws - a card that cannot be saved must not
     * affect the (already completed) top-up.
     */
    public void captureAfterTopup(TransactionModel txn) {
        try {
            if (txn == null || txn.getMetadata() == null || !txn.getMetadata().path("saveCard").asBoolean(false)
                    || txn.getReceiverId() == null || txn.getGatewayId() == null) {
                return;
            }
            GatewayModel gateway = gatewayServices.gatewayById(txn.getGatewayId());
            String reference = txn.getExternalReferenceId() != null ? txn.getExternalReferenceId()
                    : com.zentrapay.backend.service.payment.LedgerOperations.gatewayReference(txn);
            GatewayChargeStatus charge = switch (gatewayServices.nameOf(gateway)) {
                case PAYSTACK -> paystackServices.chargeStatus(reference);
                case FLUTTERWAVE -> flutterwaveServices.chargeStatus(reference);
                default -> null;
            };
            GatewayCardToken card = charge == null ? null : charge.card();
            if (card == null) {
                log.info("Card vault: {} paid without a reusable card (other channel, or tokenization is off)", reference);
                return;
            }
            if (!card.reusable()) {
                log.info("Card vault: the gateway marked the card used for {} as not reusable", reference);
                return;
            }
            save(txn.getReceiverId(), card);
        } catch (RuntimeException e) {
            log.warn("Card vault: could not save the card for transaction {}: {}",
                    txn == null ? null : txn.getTransactionId(), e.getMessage());
        }
    }

    @Transactional
    public SavedCardModel save(UUID userId, GatewayCardToken card) {
        SavedCardModel row = savedCardRepository.findByUserIdAndGatewayAndSignature(userId, card.gateway(), card.signature())
                .orElse(null);
        if (row == null) {
            if (savedCardRepository.countByUserIdAndStatus(userId, "ACTIVE") >= MAX_CARDS) {
                log.info("Card vault: user {} already keeps {} cards - not saving another", userId, MAX_CARDS);
                return null;
            }
            row = new SavedCardModel();
            row.setUserId(userId);
            row.setGateway(card.gateway());
            row.setSignature(card.signature());
        }
        boolean first = savedCardRepository.countByUserIdAndStatus(userId, "ACTIVE") == 0;
        row.setTokenEncrypted(encrypt(card.token()));
        row.setLast4(card.last4());
        row.setBrand(card.brand());
        row.setCardType(card.cardType());
        row.setBank(card.bank());
        row.setExpMonth(card.expMonth());
        row.setExpYear(card.expYear());
        row.setCountryCode(card.countryCode());
        if (!"ACTIVE".equals(row.getStatus()) || row.getId() == null) {
            row.setStatus("ACTIVE");
        }
        if (first) {
            row.setIsDefault(true);
        }
        SavedCardModel saved = savedCardRepository.save(row);
        log.info("Card vault: saved card ending {} for user {} on {}", card.last4(), userId, card.gateway());
        return saved;
    }

    // ------------------------------------------------------------------
    // Using
    // ------------------------------------------------------------------

    /** The gateway token of a card - only for the code that charges it. */
    public String tokenOf(SavedCardModel card) {
        return decrypt(card.getTokenEncrypted());
    }

    /** True once the card's expiry month has passed (unknown expiry counts as usable). */
    public static boolean isExpired(SavedCardModel card) {
        if (card.getExpMonth() == null || card.getExpYear() == null) {
            return false;
        }
        int year = card.getExpYear() < 100 ? 2000 + card.getExpYear() : card.getExpYear();
        try {
            return YearMonth.of(year, card.getExpMonth()).isBefore(YearMonth.now());
        } catch (RuntimeException e) {
            return false;
        }
    }

    /** "Visa ••4242" - what the history shows as the source of a card top-up. */
    public static String label(SavedCardModel card) {
        String brand = card.getBrand() == null || card.getBrand().isBlank() ? "Card" : card.getBrand().trim();
        return brand + " ••" + card.getLast4();
    }

    private static SavedCardDTO toDto(SavedCardModel c) {
        return new SavedCardDTO(c.getId(), c.getGateway(), c.getBrand(), c.getCardType(), c.getLast4(), c.getBank(),
                c.getExpMonth(), c.getExpYear(), Boolean.TRUE.equals(c.getIsDefault()), isExpired(c),
                c.getCreatedAt(), c.getLastUsedAt());
    }

    // AES-256-GCM, random IV in front of the ciphertext, Base64
    private String encrypt(String plain) {
        try {
            byte[] iv = new byte[12];
            RANDOM.nextBytes(iv);
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.ENCRYPT_MODE, key, new GCMParameterSpec(128, iv));
            byte[] encrypted = cipher.doFinal(plain.getBytes(StandardCharsets.UTF_8));
            byte[] out = new byte[iv.length + encrypted.length];
            System.arraycopy(iv, 0, out, 0, iv.length);
            System.arraycopy(encrypted, 0, out, iv.length, encrypted.length);
            return Base64.getEncoder().encodeToString(out);
        } catch (Exception e) {
            throw new IllegalStateException("Could not protect the card token", e);
        }
    }

    private String decrypt(String stored) {
        try {
            byte[] in = Base64.getDecoder().decode(stored);
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.DECRYPT_MODE, key, new GCMParameterSpec(128, in, 0, 12));
            return new String(cipher.doFinal(in, 12, in.length - 12), StandardCharsets.UTF_8);
        } catch (Exception e) {
            throw new IllegalStateException("Could not read the saved card", e);
        }
    }

    /** Which statuses count as "this top-up really succeeded" for the capture hook. */
    public static boolean paid(TransactionModel txn) {
        return txn != null && txn.getStatus() == Datatypes.TransactionStatus.SUCCESS;
    }
}
