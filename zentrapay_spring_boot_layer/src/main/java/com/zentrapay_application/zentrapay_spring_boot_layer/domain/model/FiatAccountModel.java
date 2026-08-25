package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Canonical fiat wallet — consolidates the old fiat_currency_accounts /
 * fiat_currencies / user_wallets (x2 conflicting mappings).
 */
@Entity
@Data
@Table(name = "accounts")
public class FiatAccountModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "account_id", nullable = false, unique = true)
    private UUID accountId;

    @Column(name = "wallet_id", nullable = false)
    private UUID walletId;

    @Column(name = "account_name", nullable = false)
    private String accountName;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @Column(name = "zentag", nullable = false)
    private String zentag;

    @Column(name = "balance", nullable = false)
    private BigDecimal balance;

    @Column(name = "is_default", nullable = false)
    private boolean isDefault;

    @Column(nullable = false, length = 50)
    private String status = "active";

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
