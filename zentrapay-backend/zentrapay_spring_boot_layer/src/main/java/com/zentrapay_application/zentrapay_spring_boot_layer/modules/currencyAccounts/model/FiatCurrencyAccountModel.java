package com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.model;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "fiat_currency_accounts")
@Data
public class FiatCurrencyAccountModel {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "account_id", unique = true, nullable = false)
    private UUID accountId;

    @Column(name = "wallet_id", nullable = false)
    private UUID walletId;

    @Column(name = "account_name", nullable = false, length = 36)
    private String accountName;

    @Column(name = "currency_code", nullable = false)
    private String currencyCode;

    @Column(name = "country_iso_code", nullable = false)
    private String countryIsoCode;

    @Column(name = "balance", nullable = false)
    private Double balance = 0.0;

    @Column(name = "status", nullable = false, updatable = false)
    private String status ="active";

    @Column(name = "created_at")
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