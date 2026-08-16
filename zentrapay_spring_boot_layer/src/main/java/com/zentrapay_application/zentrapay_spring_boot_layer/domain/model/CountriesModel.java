package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;

/**
 * Canonical mapping of the {@code countries} reference table as it actually
 * exists in the live database (country_code, country_name, region only —
 * NOT the wider V1__init_schema.sql draft, which was never applied here;
 * this app connects with ddl-auto=validate against the real table below).
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
