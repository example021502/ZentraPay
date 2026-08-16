package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.SupportedCurrenciesModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface SupportedCurrenciesRepository extends JpaRepository<SupportedCurrenciesModel, String> {

    // GETTING THE CURRENCY CODE FOR DEFAULT WALLET CREATION
    @Query("SELECT cu.currencyCode FROM SupportedCurrenciesModel cu WHERE cu.countryCode = :countryCode")
    String getCurrencyCodeByCountryCode(@Param("countryCode") String countryCode);

    // GETTING THE CURRENCY CODE FOR DEFAULT WALLET CREATION
    @Query("SELECT cu.currencyCode FROM SupportedCurrenciesModel cu WHERE cu.currencyCode NOT IN (:userCurrencyAccountsCurrencies)")
    List<String> getCurrencyCodes(@Param("userCurrencyAccountsCurrencies") List<String> userCurrencyAccountsCurrencies);

}
