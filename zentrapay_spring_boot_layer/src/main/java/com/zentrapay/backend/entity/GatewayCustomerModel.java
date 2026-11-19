package com.zentrapay.backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JavaType;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * The customer a gateway created for one of our users (Paystack CUS_xxx,
 * Flutterwave customer id ...). A user has at most one customer per gateway.
 * Every gateway recipient of that user on the same gateway points back to this row.
 */
@Entity
@Data
@Table(name = "gateway_customers",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_gateway_customers_user_gateway",
                columnNames = {"user_id", "gateway_id"}
        ))
public class GatewayCustomerModel {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    // The gateway that issued the customer (gateway_providers.provider_id)
    @Column(name = "gateway_id", nullable = false)
    private UUID gatewayId;

    // The code/id the gateway gave us for this customer
    @Column(name = "gateway_customer_code", nullable = false, length = 128)
    private String gatewayCustomerCode;

    @Column(name = "email", nullable = false)
    private String email;

    @Column(name = "status", nullable = false)
    private boolean status;

    @Column(name = "currency_code", nullable = false)
    private String currencyCode;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "metadata", columnDefinition = "jsonb")
    private String metadata;

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
