package com.zentrapay.backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

// Gateway-agnostic payout destination (Tier 1 of recipient model); gateway-specific recipient IDs live in gateway_recipients.
@Entity
@Data
@Table(
        name = "transfer_recipients",
        uniqueConstraints = {
                // Prevents duplicate saved destinations for the same user, rail type, and account/MSISDN.
                @UniqueConstraint(
                        name = "uq_recipient_owner_destination",
                        columnNames = {"user_id", "destination_type", "account_identifier"}
                )
        },
        indexes = {
                // Speeds up loading all saved payout recipients belonging to a user.
                @Index(
                        name = "idx_transfer_recipients_user_id",
                        columnList = "user_id"
                )
        }
)
public class TransferRecipientModel {

    // Primary identifier for the saved transfer recipient.
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    // User who owns this saved payout destination.
    @Column(name = "user_id", nullable = false, updatable = false)
    private UUID userId;

    // Display name of the recipient person or business.
    @Column(name = "name", nullable = false, length = 120)
    private String name;

    // Payout rail category (e.g., BANK or MOBILE_MONEY).
    @Column(name = "destination_type", nullable = false, length = 20)
    private String destinationType;

    // Bank account/NUBAN or mobile money phone number (MSISDN).
    @Column(name = "account_identifier", nullable = false, length = 50)
    private String accountIdentifier;

    // Gateway-neutral bank or mobile money operator code (e.g., MTN, GTB).
    @Column(name = "provider_code", nullable = false, length = 30)
    private String providerCode;

    // Human-readable institution or mobile money operator name (e.g., "GT Bank Ghana").
    @Column(name = "provider_name", nullable = false, length = 120)
    private String providerName;

    // ISO 3166-1 alpha-2 country code of the recipient destination (e.g., KE, NG, GH).
    @Column(name = "country_code", nullable = false, length = 2)
    private String countryCode;

    // ISO 4217 currency code for payouts to this recipient (e.g., KES, NGN, GHS).
    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    // Timestamp when the recipient was saved.
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // Timestamp automatically updated when recipient details change.
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}