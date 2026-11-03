package com.zentrapay.backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * A card the user chose to keep after paying with it: the gateway's reusable token (encrypted) and the
 * display details only. See V15. The card number / CVV never reach ZentraPay.
 */
@Entity
@Data
@Table(name = "saved_cards")
public class SavedCardModel {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "user_id", nullable = false, updatable = false)
    private UUID userId;

    // PAYSTACK or FLUTTERWAVE: a token only works on the gateway that issued it
    @Column(name = "gateway", nullable = false, length = 20, updatable = false)
    private String gateway;

    // authorization_code (Paystack) / card token (Flutterwave), AES-GCM encrypted by CardVaultService
    @Column(name = "token_encrypted", nullable = false, columnDefinition = "text")
    private String tokenEncrypted;

    @Column(name = "signature", nullable = false, length = 120, updatable = false)
    private String signature;

    @Column(name = "last4", nullable = false, length = 4)
    private String last4;

    @Column(name = "brand", length = 30)
    private String brand;

    @Column(name = "card_type", length = 30)
    private String cardType;

    @Column(name = "bank", length = 100)
    private String bank;

    @Column(name = "exp_month")
    private Integer expMonth;

    @Column(name = "exp_year")
    private Integer expYear;

    @Column(name = "country_code", length = 3)
    private String countryCode;

    @Column(name = "is_default", nullable = false)
    private Boolean isDefault = false;

    // ACTIVE or REMOVED (removed cards are kept so old transactions stay explainable, but never charged)
    @Column(name = "status", nullable = false, length = 20)
    private String status = "ACTIVE";

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @Column(name = "last_used_at")
    private LocalDateTime lastUsedAt;
}
