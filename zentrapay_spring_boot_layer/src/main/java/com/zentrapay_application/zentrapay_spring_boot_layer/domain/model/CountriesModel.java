package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;

/**
 * Canonical mapping of the {@code countries} reference table
 * (V1__init_schema.sql). ISO 3166-1 alpha-2 country code is the natural key.
 */
@Entity
@Data
@Table(name = "countries")
public class CountriesModel {
    @Id
    @Column(name = "country_code", nullable = false, length = 2)
    private String countryCode;

    @Column(name = "country_name", nullable = false, length = 80)
    private String countryName;

    @Column(name = "region", length = 40)
    private String region;

}
