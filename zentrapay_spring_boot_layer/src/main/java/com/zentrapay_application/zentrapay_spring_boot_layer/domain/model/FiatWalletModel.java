package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Canonical fiat wallet — consolidates the old fiat_currency_accounts /
 * fiat_currencies / user_wallets (x2 conflicting mappings).
 */
@Entity
@Data
@Table(name = "wallets")
public class FiatWalletModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "wallet_id", nullable = false)
    private UUID walletId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "wallet_name", nullable = false)
    private String walletName;

    @Column(name = "country_code", nullable = false, length = 3)
    private String countryCode;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
