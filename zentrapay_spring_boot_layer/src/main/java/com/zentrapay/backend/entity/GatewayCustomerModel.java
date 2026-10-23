package com.zentrapay.backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * The customer a gateway created for one of our users (Paystack CUS_xxx,
 * Flutterwave customer id ...). A user has at most one customer per gateway.
 * Every gateway recipient of that user on the same gateway points back to this row.
 */
@Entity
@Data
@Table(name = "gateway_customers")
public class GatewayCustomerModel {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false, updatable = false)
    private Integer id;

    // Our user (users.user_id)
    @Column(name = "user_id", nullable = false)
    private UUID userId;

    // The gateway that issued the customer (gateway_providers.provider_id)
    @Column(name = "gateway_id", nullable = false)
    private UUID gatewayId;

    @Column(name = "email", length = 100)
    private String email;

    // The code/id the gateway gave us for this customer
    @Column(name = "gateway_customer_id", nullable = false, length = 128)
    private String gatewayCustomerId;

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
