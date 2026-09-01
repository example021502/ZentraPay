package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Entity storing gateway recipient codes for bank accounts and mobile money transfers.
 * Maps local payout destinations to external provider recipient codes (e.g., Paystack RCP_xxxx).
 * <p>
 * Mapped to the externally-managed {@code gateway_recipients} table:
 * {@code id bigint GENERATED ALWAYS AS IDENTITY}, {@code user_id uuid} (FK to users),
 * {@code gateway_recipient_id} (local record id), {@code gateway_recipient_code}
 * (gateway token), {@code channel_code}, {@code gateway_id uuid}
 * (FK to gateway_providers.provider_id) and {@code gateway varchar(100)}.
 */
@Entity
@Data
@Table(name = "gateway_recipients")
public class GatewayRecipientsModel {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false, updatable = false)
    private Long id;

    /** Local owner of the gateway recipient record (FK users.user_id). */
    @Column(name = "user_id", nullable = false)
    private UUID userId;

    /** FK to gateway_providers.provider_id for the gateway below. */
    @Column(name = "gateway_id", nullable = false)
    private UUID gatewayId;

    /**
     * Gateway identifier the recipient code was registered under
     * (PAYSTACK / FLUTTERWAVE / ONAFRIQ — see GatewayCustomerService).
     */
    @Column(name = "gateway", length = 100)
    private String gatewayName;

    /** Locally generated record identifier (NanoId) for this mapping. */
    @Column(name = "gateway_recipient_id", nullable = false, length = 128)
    private String gatewayRecipientId;

//    /** Recipient code / token returned by the gateway (e.g. RCP_xxxx). */
//    @Column(name = "gateway_recipient_code", nullable = false, length = 128)
//    private String gatewayRecipientCode;

    /** Neutral payout channel of the destination (BANK / MOBILE_MONEY). */
    @Column(name = "checkoutType", nullable = false, length = 32)
    private String checkoutType;
//  the destination checkout source code - bank code, mobile money code etc
    @Column(name = "channel_code", nullable = false, length = 32)
    private String channelCode;
//  destination account identifier - account number, phone number etc
    @Column(name = "account_identifier", nullable = false, length = 64)
    private String accountIdentifier;
//  destination account name
    @Column(name = "account_name", nullable = false, length = 150)
    private String accountName;

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}