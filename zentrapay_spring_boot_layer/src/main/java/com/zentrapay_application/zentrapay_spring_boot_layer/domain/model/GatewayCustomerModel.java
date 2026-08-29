package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

/**
 * Entity mapping local users to gateway-specific Customer IDs
 * (e.g., Paystack customer_code, Flutterwave customer ID).
 */
@Entity
@Data
@Table(
        name = "gateway_customers",
        uniqueConstraints = {
                // Enforces a single gateway customer record per user and payment gateway pair
                @UniqueConstraint(name = "uq_user_gateway_customer", columnNames = {"user_id", "gateway_name"})
        }
)
public class GatewayCustomerModel {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false, updatable = false)
    private Long id;

    @Column(name = "user_id", nullable = false, length = 64)
    private String userId;

    @Column(name = "gateway_name", nullable = false, length = 32)
    private String gatewayName;

    @Column(name = "gateway_customer_id", nullable = false, length = 128)
    private String gatewayCustomerId;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}