package com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.model;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Entity
@Table(name = "crypto_currencies")
@Data
public class CryptoAccountModel {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "account_id", unique = true, nullable = false)
    private String accountId;

    @Column(name = "user_id", nullable = false)
    private String userId;

    @Column(name = "currency_code", nullable = false, length = 10)
    private String currencyCode;

    @Column(name = "currency_name", nullable = false)
    private String currencyName;

    @Column(name = "network", nullable = false)
    private String network;

    @Column(name = "balance", nullable = false)
    private Double balance = 0.0;

    @Column(name = "status", nullable = false, length = 20)
    private String status = "ACTIVE";

    @Column(name = "wallet_address", unique = true, nullable = false)
    private String walletAddress;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

}
