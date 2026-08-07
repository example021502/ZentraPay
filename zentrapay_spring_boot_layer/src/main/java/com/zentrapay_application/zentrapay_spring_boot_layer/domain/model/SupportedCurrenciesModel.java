package com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.models;

import jakarta.persistence.*;

import java.util.UUID;

@Entity
@Table(name = "gateway_accounts_supported_currencies")
public class SupportedCurrenciesModel {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(nullable = false, unique = true, name = "currency_id")
    private UUID currency_id;

    @Column(name = "account_id", nullable = false)
    private UUID accountId; // e.g., USD, EUR, INR

    @Column(name = "currency_code", nullable = false)
    private String currencyCode; // e.g., USD, EUR, INR

    @Column(name = "currency_name", nullable = false)
    private String currencyName; // e.g., US Dollar

    @Column(name = "is_crypto", nullable = false)
    private Boolean isCrypto;

    @Column(name = "is_default", nullable = false)
    private Boolean isDefault;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive;

    @Column(name = "country_iso_code", nullable = false)
    private String countryIsoCode;

    @Column(name = "country_name", nullable = false)
    private String countryName;

}