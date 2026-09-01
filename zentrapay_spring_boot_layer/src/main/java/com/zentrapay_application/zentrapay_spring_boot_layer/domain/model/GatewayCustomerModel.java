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
@Table(name = "gateway_customers")
public class GatewayCustomerModel {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false, updatable = false)
    private Integer id;

    /** Local owner of the gateway recipient record (FK users.user_id). */
    @Column(name = "user_id", nullable = false)
    private UUID userId;

    /** FK to gateway_providers.provider_id for the gateway below. */
    @Column(name = "gateway_id", nullable = false)
    private UUID gatewayId;

    @Column(name = "gateway", length = 100)
    private String gatewayName;

    @Column(name = "email", length = 100)
    private String email;

    /** Locally generated record identifier (NanoId) for this mapping. */
    @Column(name = "gateway_customer_id", nullable = false, length = 128)
    private String gatewayCustomerId;

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}