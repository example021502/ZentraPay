package com.zentrapay.backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * One row per connected gateway (PAYSTACK / FLUTTERWAVE / ONAFRIQ ...).
 * Which gateway is primary or the failover is NOT stored here - it is decided
 * in code (see GatewayServices) from the corridor of the payment.
 */
@Entity
@Data
@Table(name = "gateway_providers")
public class GatewayModel {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "provider_id", nullable = false)
    private UUID providerId;

    // Upper case name, e.g. PAYSTACK (matches Datatypes.PaymentGateway)
    @Column(name = "provider_name", nullable = false, unique = true)
    private String providerName;

    @Column(name = "description", nullable = false)
    private String description;

    @Column(name = "is_active", nullable = false)
    private Boolean active;

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;
}
