package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

/**
 * Entity storing gateway recipient codes for bank accounts and mobile money transfers.
 * Maps local payout destinations to external provider recipient codes (e.g., Paystack RCP_xxxx).
 */
@Entity
@Data
@Table(
        name = "gateway_recipients",
        uniqueConstraints = {
                // Prevents duplicate recipient entries for the same account on a specific gateway
                @UniqueConstraint(
                        name = "uq_user_recipient_per_gateway",
                        columnNames = {"user_id", "gateway_name", "account_identifier", "provider_code"}
                )
        }
)
public class GatewayRecipientsModel {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false, updatable = false)
    private Long id;

    @Column(name = "user_id", nullable = false, length = 64)
    private String userId;

    @Column(name = "gateway_name", nullable = false, length = 32)
    private String gatewayName;

    @Column(name = "gateway_recipient_code", nullable = false, length = 128)
    private String gatewayRecipientCode;

    @Column(name = "channel_type", nullable = false, length = 32)
    private String channelType;

    @Column(name = "gateway_type", nullable = false, length = 32)
    private String gatewayType;

    @Column(name = "account_identifier", nullable = false, length = 64)
    private String accountIdentifier;

    @Column(name = "provider_code", nullable = false, length = 32)
    private String providerCode;

    @Column(name = "account_name", nullable = false, length = 150)
    private String accountName;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}