package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.CurrencyModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface CurrencyRepository extends JpaRepository<CurrencyModel, String> {
    @Query("SELECT c FROM CurrencyModel c WHERE c.currencyCode IN (:currencyCodes)")
    List<CurrencyModel> getCurrenciesByCurrencyCodes(@Param("currencyCodes") List<String>currencyCodes);
}
