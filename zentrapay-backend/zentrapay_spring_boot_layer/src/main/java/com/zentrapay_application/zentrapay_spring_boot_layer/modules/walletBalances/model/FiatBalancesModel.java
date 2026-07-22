package com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.model;

import jakarta.persistence.*;
import lombok.Data;

// FIAT CURRENCY DATA
@Entity
@Table(name = "fiat_currencies")
@Data // Requires Lombok dependency
public class WalletBalancesModel {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(nullable = false, name = "fiat_id", unique = true)
    private String fiatId;

    @Column(nullable = false, name = "currency_name")
    private String currencyName;

    @Column(nullable = false, name = "currency_code")
    private String currencyCode;

    @Column(nullable = false, name = "balance")
    private String balance;

    @Column(nullable = false, name = "date_created")
    private String dateCreated; // Stores bcrypt hash

    @Column(nullable = false, name = "country_iso_code")
    private String countryIsoCode;      // Stores bcrypt hash
}

//CRYPTO CURRENCY DATA
@Entity
@Table(name = "crypto_currencies")
@Data // Requires Lombok dependency
public class WalletBalancesModel {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(nullable = false, name = "fiat_id", unique = true)
    private String fiatId;

    @Column(nullable = false, name = "currency_name")
    private String currencyName;

    @Column(nullable = false, name = "currency_code")
    private String currencyCode;

    @Column(nullable = false, name = "balance")
    private String balance;

    @Column(nullable = false, name = "date_created")
    private String dateCreated; // Stores bcrypt hash

    @Column(nullable = false, name = "country_iso_code")
    private String countryIsoCode;      // Stores bcrypt hash

}