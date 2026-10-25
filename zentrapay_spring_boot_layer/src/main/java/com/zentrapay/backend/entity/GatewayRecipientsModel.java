package com.zentrapay.backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * A payout destination (bank account or mobile-money wallet) registered on ONE gateway
 * (Paystack RCP_xxx, Flutterwave beneficiary id ...).
 *
 * <p>Rule: a recipient belongs to the customer of the SAME gateway. The database
 * enforces it with a composite foreign key ({@code customer_id, gateway_id}) onto
 * {@code gateway_customers}, so a Paystack recipient can never point at a Flutterwave customer.
 */
@Entity
@Data
@Table(name = "gateway_recipients")
public class GatewayRecipientsModel {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false, updatable = false)
    private Long id;

    // Owner of the destination (users.user_id)
    @Column(name = "user_id", nullable = false)
    private UUID userId;

    // Gateway the recipient was registered on (gateway_providers.provider_id)
    @Column(name = "gateway_id", nullable = false)
    private UUID gatewayId;

    // The customer (gateway_customers.id) of the same gateway
    @Column(name = "customer_id", nullable = false)
    private Integer customerId;

    // BANK or MOBILE_MONEY
    @Column(name = "checkout_type", nullable = false, length = 32)
    private String checkoutType;

    // Bank code / mobile-money provider code, as THIS gateway knows it
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
