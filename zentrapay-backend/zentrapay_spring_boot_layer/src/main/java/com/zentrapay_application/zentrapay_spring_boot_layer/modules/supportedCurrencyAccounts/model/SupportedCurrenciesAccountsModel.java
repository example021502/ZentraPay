package com.zentrapay_application.zentrapay_spring_boot_layer.modules.supportedCurrencyAccounts.model;

import jakarta.persistence.*;
import lombok.Data;

import java.util.UUID;

@Entity
@Table(name = "gateway_accounts_supported_currencies")
@Data
public class SupportedCurrenciesAccountsModel {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "currency_id", unique = true, nullable = false)
    private UUID currencyId;

    @Column(name = "account_id", nullable = false)
    private UUID accountId;

    @Column(name = "currency_code", nullable = false)
    private UUID currencyCode;

    @Column(name = "currency_name", length = 3)
    private String currencyName;

    @Column(name = "is_crypto")
    private Boolean isCrypto = true;

    @Column(name = "is_default")
    private Boolean isDefault = true;

    @Column(name = "is_active")
    private Boolean isActive = true;

}
