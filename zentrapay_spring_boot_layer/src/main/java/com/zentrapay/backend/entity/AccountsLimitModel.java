package com.zentrapay.backend.entity;

import com.zentrapay.backend.service.common.Datatypes;
import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

// Stores bank and mobile-money channel metadata synced from payment gateways per currency/corridor.
@Entity
@Data
@Table(
        name = "banks",
        uniqueConstraints = @UniqueConstraint(
                // Prevents duplicate bank codes within the same gateway and currency scope.
                name = "uk_banks_gateway_code_currency",
                columnNames = {"gateway_id", "code", "currency_code"}
        )
)

public class AccountsLimitModel {
    // Primary identifier for the synced bank/channel record.
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    // Gateway-specific bank or channel code (matches GatewayRecipientsModel.channelCode).
    @Column(name = "limit", nullable = false, length = 32)
    private BigDecimal limit;

    // Display name of the bank or mobile-money institution.
    @Column(name = "kycTier", nullable = false)
    private short kycTier;

    // ISO currency code such as KES, NGN, or GHS.
    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    // Date created
    @CreationTimestamp
    @Column(name = "created_at", updatable = false, nullable = false)
    private LocalDateTime createdAt;

    // Date updated
    @CreationTimestamp
    @Column(name = "updated_at", updatable = false, nullable = false)
    private LocalDateTime updatedAt;
}