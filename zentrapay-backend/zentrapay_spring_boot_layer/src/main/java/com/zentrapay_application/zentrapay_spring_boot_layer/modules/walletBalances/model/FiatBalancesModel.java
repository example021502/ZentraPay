package com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.model;

import jakarta.persistence.*;
import lombok.Data;

import java.math.BigDecimal;
import java.util.UUID;

// FIAT CURRENCY DATA
@Entity
@Table(name = "fiat_currencies")
@Data // Requires Lombok dependency
public class FiatBalancesModel {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(nullable = false, name = "fiat_id", unique = true)
    private String fiatId;

    @Column(nullable = false, name = "user_id")
    private UUID userId;

    @Column(nullable = false, name = "currency_name")
    private String currencyName;

    @Column(nullable = false, name = "currency_code")
    private String currencyCode;

    @Column(nullable = false, name = "currency")
    private String currency;

    @Column(nullable = false, name = "balance")
    private BigDecimal balance;

    @Column(nullable = false, name = "date_created")
    private String dateCreated;

    @Column(nullable = false, name = "country_iso_code")
    private String countryIsoCode;
}
