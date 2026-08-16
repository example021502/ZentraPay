package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;

import java.util.UUID;

@Entity
@Data
@Table(name = "gateway_account_currencies")
public class SupportedCurrenciesModel {
    @Id
    @Column(name = "currency_id", nullable = false, unique = true)
    private UUID currencyId;

    @Column(name = "account_id", nullable = false)
    private UUID accountId;

    @Column(name = "currency_code", nullable = false)
    private String currencyCode;

    @Column(name = "is_crypto", nullable = false)
    private boolean isCrypto;

    @Column(name = "is_default", nullable = false)
    private boolean isDefault;

    @Column(name = "active", nullable = false)
    private boolean active;

    @Column(name = "country_code", nullable = false)
    private String countryCode;

    @Column(name = "decimal_places", nullable = false)
    private short decimalPlaces;
}
