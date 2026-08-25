package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.GatewayCurrencyModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface GatewayCurrenciesRepository extends JpaRepository<GatewayCurrencyModel, String> {

    // Default wallet currency for a given registration country.
    @Query("SELECT cu.currencyCode FROM GatewayCurrencyModel cu WHERE cu.countryCode = :countryCode AND cu.active = true")
    List<String> getCurrencyCodesByCountryCode(@Param("countryCode") String countryCode);

    // Currencies the user has NOT opened an account for yet — candidates for new accounts.
    @Query("SELECT cu.currencyCode FROM GatewayCurrencyModel cu WHERE cu.currencyCode NOT IN (:userCurrencyAccountsCurrencies) AND cu.active = true")
    List<String> getCurrencyCodes(@Param("userCurrencyAccountsCurrencies") List<String> userCurrencyAccountsCurrencies);

    @Query("SELECT c FROM GatewayCurrencyModel c WHERE c.currencyCode IN (:currencyCodes)")
    List<GatewayCurrencyModel> getCurrenciesByCurrencyCodes(@Param("currencyCodes") List<String> currencyCodes);

    List<GatewayCurrencyModel> findByActive(boolean active);
}