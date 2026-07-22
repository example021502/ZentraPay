package com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.model;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Entity
@Table(name = "crypto_wallets")
@Data
public class CryptoWallet {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "wallet_id", unique = true, nullable = false)
    private String walletId;

    @Column(name = "user_id", nullable = false, unique = true)
    private String userId;

    @Column(name = "wallet_name", nullable = false, length = 50)
    private String walletName;

    @Column(name = "total_balance", nullable = false)
    private Double totalBalance = 0.0;

    @Column(name = "status", nullable = false, length = 20)
    private String status = "ACTIVE";

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}