package com.zentrapay.backend.entity;

import com.zentrapay.backend.service.common.Datatypes;
import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

// Stores tokenized payment card metadata and encrypted gateway authorization tokens for saved user cards.
@Entity
@Data
@Table(
        name = "user_cards",
        uniqueConstraints = {
                // Prevents saving the exact same card fingerprint multiple times for a user under one provider.
                @UniqueConstraint(
                        name = "uk_user_cards_user_provider_signature",
                        columnNames = {"user_id", "provider", "signature"}
                )
        },
        indexes = {
                // Speeds up loading a user's active or historical saved cards.
                @Index(
                        name = "idx_user_cards_user_status",
                        columnList = "user_id, status"
                )
        }
)
public class UserCardModel {

    // Primary identifier for the saved card record.
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    // Owner user ID who saved the card.
    @Column(name = "user_id", nullable = false, updatable = false)
    private UUID userId;

    // Payment gateway / token provider code (e.g., PAYSTACK, FLUTTERWAVE).
    @Column(name = "provider", nullable = false, length = 20, updatable = false)
    private String provider;

    // Encrypted reusable gateway token/authorization code (raw PAN and CVV are never stored).
    @Column(name = "token_encrypted", nullable = false, columnDefinition = "text")
    private String tokenEncrypted;

    // Gateway card fingerprint/signature used to detect duplicate saved cards.
    @Column(name = "signature", nullable = false, length = 120, updatable = false)
    private String signature;

    // Last four digits of the card for display purposes.
    @Column(name = "last4", nullable = false, length = 4, updatable = false)
    private String last4;

    // Card brand/scheme (e.g., VISA, MASTERCARD, VERVE).
    @Column(name = "brand", length = 30)
    private String brand;

    // Card funding type (e.g., DEBIT, CREDIT, PREPAID).
    @Column(name = "card_type", nullable = false)
    private Datatypes.CardType cardType = Datatypes.CardType.DEBIT;

    // Issuing bank name reported by the gateway.
    @Column(name = "bank", length = 100)
    private String bank;

    // Two-digit or numeric card expiration month (1-12).
    @Column(name = "exp_month")
    private Integer expMonth;

    // Four-digit card expiration year.
    @Column(name = "exp_year")
    private Integer expYear;

    // ISO country code associated with the card (e.g., KE, NG, GH).
    @Column(name = "country_code", length = 3)
    private String countryCode;

    // Indicates whether this card is pre-selected by default for card charges.
    @Column(name = "is_default", nullable = false)
    private Boolean isDefault = false;

    // Card lifecycle state: ACTIVE or REMOVED (retained for auditability, never charged when REMOVED).
    @Column(name = "status", nullable = false, length = 20)
    private Datatypes.CardStatus status = Datatypes.CardStatus.ACTIVE;

    // Timestamp when the card token was saved.
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // Timestamp automatically updated when card metadata, default flag, or status changes.
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    // Timestamp of the last successful charge made using this saved card.
    @Column(name = "last_used_at")
    private LocalDateTime lastUsedAt;

}