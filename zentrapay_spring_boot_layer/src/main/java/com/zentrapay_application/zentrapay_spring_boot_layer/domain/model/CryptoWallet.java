package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Canonical crypto wallet — consolidates the old currencyAccounts.CryptoAccountModel
 * and walletBalances.CryptoBalancesModel (both mapped "crypto_currencies" with
 * incompatible columns, one even typing balance as a String).
 *
 * Table/entity only — balance-affecting service logic is intentionally left
 * as TODO in this pass (crypto wallet logic ships in a later iteration).
 */
@Entity
@Data
@Table(name = "crypto_wallets")
public class CryptoWallet {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "crypto_wallet_id", nullable = false)
    private UUID cryptoWalletId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @Column(length = 30)
    private String network;

    @Column(name = "wallet_address", nullable = false, unique = true, length = 120)
    private String walletAddress;

    @Column(nullable = false, precision = 28, scale = 10)
    private BigDecimal balance = BigDecimal.ZERO;

    @Column(nullable = false, length = 20)
    private String status = "ACTIVE";

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
