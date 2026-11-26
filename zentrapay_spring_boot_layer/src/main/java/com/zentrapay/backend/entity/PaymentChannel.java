package com.zentrapay.backend.entity;

import com.zentrapay.backend.service.common.Datatypes;
import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

// Represents an available payment/collection channel (e.g., BANK, MOBILE_MONEY, CARD) per gateway and country.
@Entity
@Data
@Table(
        name = "payment_channels",
        uniqueConstraints = {
                // Prevents duplicate channel codes for the same gateway within a country.
                @UniqueConstraint(
                        name = "uk_payment_channels_gateway_code_country",
                        columnNames = {"gateway", "channel_code", "country_code"}
                )
        },
        indexes = {
                // Speeds up queries for active payment channels available in a user's country.
                @Index(
                        name = "idx_payment_channels_country_active",
                        columnList = "country_code, is_active"
                )
        }
)
public class PaymentChannel {

    // Surrogate primary key so multiple gateways can define the same channel_code without colliding.
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    // Gateway-specific channel identifier (e.g., "BANK_TRANSFER", "MPESA", "CARD").
    @Column(name = "channel_code", nullable = false, length = 30)
    private String channelCode;

    // Human-readable label shown to users on checkout or payout screens.
    @Column(name = "channel_name", nullable = false, length = 120)
    private String channelName;

    // High-level rail category (e.g., BANK, MOBILE_MONEY, CARD).
    @Column(name = "channel_type", nullable = false, length = 20)
    private String channelType;

    // ISO 3166-1 alpha-2 country code where this channel is supported (e.g., "KE", "NG", "GH").
    @Column(name = "country_code", nullable = false, length = 2)
    private String countryCode;

    // Payment gateway code providing this channel (e.g., "PAYSTACK", "FLUTTERWAVE", "MPESA_DARAJA").
    @Column(name = "gateway", nullable = false, length = 30)
    private Datatypes.Gateway gateway;

    // Indicates whether this channel is currently enabled for transactions.
    @Column(name = "is_active", nullable = false)
    private boolean isActive = true;

    // Timestamp when the channel record was created.
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // Timestamp automatically updated when the channel record changes.
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}