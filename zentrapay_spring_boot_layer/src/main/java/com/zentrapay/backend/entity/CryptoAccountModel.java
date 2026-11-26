package com.zentrapay.backend.entity;

import com.zentrapay.backend.service.common.Datatypes;
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
 * <p>
 * Table/entity only — balance-affecting service logic is intentionally left
 * as TODO in this pass (crypto wallet logic ships in a later iteration).
 */
@Entity
@Data
@Table(name = "crypto_accounts")
public class CryptoAccountModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, unique = true)
    private UUID id;

    @Column(name = "user_id", nullable = false, length = 20)
    private UUID userId;

    @Column(name = "network", length = 30)
    private String network;

    @Column(name = "address", nullable = false, unique = true, length = 120)
    private String address;

    @Column(name = "balance", nullable = false, precision = 28, scale = 10)
    private BigDecimal balance;

    @Column(name = "currency_code", nullable = false, length = 20)
    private String currencyCode;

    @Column(name = "is_default", nullable = false)
    private Boolean isDefault;

    @Column(name = "status", nullable = false)
    private Datatypes.AccountStatus status = Datatypes.AccountStatus.ACTIVE;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
