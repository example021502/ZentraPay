package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Canonical card — consolidates the old cards.CardsModel and
 * zpay.CardModel (both mapped "cards" with different, incompatible columns).
 */
@Entity
@Data
@Table(name = "cards")
public class Card {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "card_id", nullable = false)
    private UUID cardId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "wallet_id")
    private UUID walletId;

    @Column(nullable = false, length = 30)
    private String brand;

    @Column(name = "card_type", nullable = false, length = 20)
    private String cardType = "VIRTUAL"; // VIRTUAL, PHYSICAL

    @Column(nullable = false, length = 4)
    private String last4;

    @Column(name = "expiry_month", nullable = false)
    private short expiryMonth;

    @Column(name = "expiry_year", nullable = false)
    private short expiryYear;

    @Column(name = "nfc_enabled", nullable = false)
    private boolean nfcEnabled = true;

    @Column(name = "qr_enabled", nullable = false)
    private boolean qrEnabled = true;

    @Column(nullable = false, length = 20)
    private String status = "ACTIVE";

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
