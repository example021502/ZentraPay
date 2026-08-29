package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Gateway-agnostic payout destination (tier 1 of the two-tier recipient
 * structure). Stores WHAT the destination is (bank account vs mobile-money
 * wallet), never a gateway-specific token — those live in
 * {@link RecipientGatewayTokenModel} per gateway.
 * <p>
 * Table managed externally — this class is a mapping only.
 */
@Entity
@Data
@Table(
        name = "transfer_recipients",
        uniqueConstraints = @UniqueConstraint(
                name = "uq_recipient_owner_destination",
                columnNames = {"user_id", "destination_type", "account_identifier"})
)
public class TransferRecipientModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "recipient_id", nullable = false)
    private UUID recipientId;

    /** Owner of this payout destination. */
    @Column(name = "user_id", nullable = false)
    private UUID userId;

    /** Display name of the person/business receiving the payout. */
    @Column(name = "recipient_name", nullable = false, length = 120)
    private String recipientName;

    /** BANK (account -> nuban) | MOBILE_MONEY (wallet -> mobile_money). */
    @Column(name = "destination_type", nullable = false, length = 20)
    private String destinationType;

    /** Bank account number, or MSISDN for MOBILE_MONEY. */
    @Column(name = "account_identifier", nullable = false, length = 50)
    private String accountIdentifier;

    /** Gateway-neutral provider code (bank code / momo provider, e.g. MTN). */
    @Column(name = "provider_code", nullable = false, length = 30)
    private String providerCode;

    /** Human-readable provider name (e.g. "GT Bank Ghana"). */
    @Column(name = "provider_name", nullable = false, length = 120)
    private String providerName;

    @Column(name = "country_code", nullable = false, length = 3)
    private String countryCode;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}