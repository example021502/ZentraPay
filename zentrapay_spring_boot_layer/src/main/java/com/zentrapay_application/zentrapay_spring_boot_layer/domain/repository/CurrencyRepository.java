package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.CurrencyModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface CurrencyRepository extends JpaRepository<CurrencyModel, String> {
    List<CurrencyModel> findByIsActiveTrue();
    List<CurrencyModel> findByIsCrypto(boolean isCrypto);

    // Resolves the default currency for a country code (ISO 3166-1 alpha-2) from the
    // reference `countries` table. The `currencies` table has no country dimension, and
    // there is no Country entity for the `countries` table, so a native query is used.
    @Query(value = "SELECT default_currency_code FROM countries WHERE country_code = :countryCode", nativeQuery = true)
    String getCurrencyCodeByCountryCode(@Param("countryCode") String countryCode);

}
