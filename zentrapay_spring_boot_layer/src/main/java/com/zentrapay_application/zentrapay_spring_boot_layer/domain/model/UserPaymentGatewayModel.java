package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Gateway-customer registration per user, per gateway (multi-gateway
 * architecture). Gateway customer IDs are NEVER stored on the main
 * {@code users} entity — each gateway (PAYSTACK / ONAFRIQ / FLUTTERWAVE)
 * issues its own customer identity, cached here so a user is only ever
 * registered at a gateway once.
 * <p>
 * Table managed externally — this class is a mapping only.
 */
@Entity
@Data
@Table(
        name = "user_payment_gateways",
        uniqueConstraints = @UniqueConstraint(
                name = "uq_user_gateway",
                columnNames = {"user_id", "gateway_name"})
)
public class UserPaymentGatewayModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "user_gateway_id", nullable = false)
    private UUID userGatewayId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    /** PAYSTACK | ONAFRIQ | FLUTTERWAVE (normalized uppercase). */
    @Column(name = "gateway_name", nullable = false, length = 30)
    private String gatewayName;

    /** Customer identity returned by the gateway (e.g. Paystack CUS_xxx). */
    @Column(name = "gateway_customer_id", nullable = false, length = 100)
    private String gatewayCustomerId;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}