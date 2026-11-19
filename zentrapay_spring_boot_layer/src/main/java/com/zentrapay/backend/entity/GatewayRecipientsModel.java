package com.zentrapay.backend.entity;

import com.zentrapay.backend.service.common.Datatypes;
import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Data
@Table(name = "gateway_recipients")
public class GatewayRecipientsModel {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    // Owner of the destination (users.user_id)
    @Column(name = "user_id", nullable = false)
    private UUID userId;

    // Gateway the recipient was registered on (gateway_providers.provider_id)
    @Column(name = "gateway_id", nullable = false)
    private UUID gatewayId;

    // BANK or MOBILE_MONEY
    @Column(name = "payout_type", nullable = false)
    private Datatypes.PayoutType payoutType;

    @Column(name = "channel_code", nullable = false, length = 32)
    private String channelCode;

    // Account number or phone number
    @Column(name = "account_identifier", nullable = false, length = 64)
    private String accountIdentifier;

    @Column(name = "account_name", nullable = false, length = 150)
    private String accountName;

    // The code/id the gateway gave us for this recipient
    @Column(name = "gateway_recipient_code", nullable = false, length = 128)
    private String gatewayRecipientCode;

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
