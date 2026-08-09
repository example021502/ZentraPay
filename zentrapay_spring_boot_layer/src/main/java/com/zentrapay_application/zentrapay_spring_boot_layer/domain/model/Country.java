package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;

import java.util.UUID;

@Entity
@Data
@Table(name = "gateway_account_countries")
public class Country {
    @Id
    @Column(name = "country_id", nullable = false, unique = true)
    private UUID countryId;


    @Column(name = "account_id", nullable = false)
    private UUID accountId;


    @Column(name = "country_iso_code", nullable = false, length = 3)
    private String countryIsoCode;

    @Column(name = "is_default", nullable = false)
    private Boolean isDefault;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive;

}
