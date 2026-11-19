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
@Table(name = "gateways")
public class GatewayModel {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    // PAYSTACK, FLUTTERWAVE, ONAFRIQ, FINCRA
    @Column(name = "code", nullable = false, unique = true)
    private String code;

    // Paystack, flutterwave, onafriq, fincra
    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "description")
    private String description;

    @Column(name = "active", nullable = false)
    private boolean active = true;

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;
}
