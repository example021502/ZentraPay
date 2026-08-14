package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Data
@Table(name = "currencies")
public class CurrencyModel {
    @Id
    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @Column(name = "currency_name", nullable = false, length = 60)
    private String currencyName;

    @Column(nullable = false, length = 8)
    private String symbol;

    @Column(name = "is_crypto", nullable = false)
    private boolean isCrypto;

    @Column(name = "decimal_places", nullable = false)
    private short decimalPlaces;

    @Column(name = "is_active", nullable = false)
    private boolean isActive;
}
