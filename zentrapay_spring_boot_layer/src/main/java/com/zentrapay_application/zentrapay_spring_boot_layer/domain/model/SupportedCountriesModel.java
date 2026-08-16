package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;

import java.util.UUID;

/**
 * Canonical mapping of the {@code countries} reference table
 * (V1__init_schema.sql). ISO 3166-1 alpha-2 country code is the natural key.
 */
@Entity
@Data
@Table(name = "gateway_account_countries")
public class SupportedCountriesModel {
    @Id
    @Column(name = "country_id", nullable = false, unique = true)
    private UUID countryId;

    @Column(name = "account_id", nullable = false)
    private UUID accountId;

    @Column(name = "country_code", nullable = false)
    private String countryCode;

    @Column(name = "is_default", nullable = false)
    private Boolean isDefault;

    @Column(name = "active", nullable = false)
    private Boolean active;

}
