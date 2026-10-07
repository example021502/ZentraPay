package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Canonical card — consolidates the old cards.CardsModel and
 * zpay.CardModel (both mapped "cards" with different, incompatible columns).
 */
@Entity
@Data
@Table(name = "user_cards")
public class UserCardsModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, unique = true)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "card_id", nullable=false)
    private UUID cardId;

    @Column(name = "wallet_id", nullable = false)
    private UUID walletId;

    @Column(name = "provider_id", nullable = false)
    private UUID providerId;

    @Column(name = "last4", nullable = false, length=4)
    private String last4;

    @Column(name = "expiry_month", nullable = false, length=2)
    private Integer expiryMonth;

    @Column(name = "expiry_year", nullable = false, length=2)
    private Integer expiryYear;

    @Column(name = "nfc_enabled", nullable = false)
    private Boolean nfcEnabled;

    @Column(name = "qr_enabled", nullable = false)
    private Boolean qrEnabled;

    @Column(name = "balance", nullable = false)
    private BigDecimal balance = BigDecimal.ZERO;

    @Column(name = "currencyCode", nullable = false, length = 3)
    private String currencyCode;

    @Column(name = "status", nullable = false, length = 20)
    private String status = "ACTIVE";

    @CreationTimestamp
    @Column(name = "issued_at", nullable = false)
    private LocalDateTime issuedAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

}
