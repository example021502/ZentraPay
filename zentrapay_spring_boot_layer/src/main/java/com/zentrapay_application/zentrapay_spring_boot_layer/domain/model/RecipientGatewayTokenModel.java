package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Tier 2 of the two-tier recipient structure: maps a local
 * {@link TransferRecipientModel} to its gateway-specific token
 * (e.g. Paystack {@code recipient_code} RCP_xxx). A recipient can hold one
 * row per gateway; before executing an outbound transfer we look the token
 * up here first and only call the gateway's transferrecipient endpoint when
 * it is missing.
 * <p>
 * Table managed externally — this class is a mapping only.
 */
@Entity
@Data
@Table(
        name = "recipient_gateway_tokens",
        uniqueConstraints = @UniqueConstraint(
                name = "uq_recipient_gateway",
                columnNames = {"recipient_id", "gateway_name"})
)
public class RecipientGatewayTokenModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "token_id", nullable = false)
    private UUID tokenId;

    @Column(name = "recipient_id", nullable = false)
    private UUID recipientId;

    /** PAYSTACK | ONAFRIQ | FLUTTERWAVE (normalized uppercase). */
    @Column(name = "gateway_name", nullable = false, length = 30)
    private String gatewayName;

    /** Gateway token, e.g. Paystack recipient_code "RCP_...". */
    @Column(name = "gateway_recipient_code", nullable = false, length = 100)
    private String gatewayRecipientCode;

    /** Gateway-native recipient type, e.g. "nuban" or "mobile_money". */
    @Column(name = "gateway_type", nullable = false, length = 30)
    private String gatewayType;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}