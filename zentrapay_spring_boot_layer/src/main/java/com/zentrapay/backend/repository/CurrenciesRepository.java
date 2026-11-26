package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.CurrenciesModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface CurrenciesRepository extends JpaRepository<CurrenciesModel, UUID> {

    @Query("SELECT c FROM CurrenciesModel WHERE c.code NOT IN (:codes)")
    List<CurrenciesModel> getCurrenciesByCodes(@Param("codes") List<String> codes);

    boolean existsByCurrencyCode(@Param("currencyCode") String currencyCode);

    @Query("SELECT c.code FROM CurrenciesModel c WHERE c.countryCode =:countryCode")
    String getCurrencyCodeByCountryCode(String countryCode);
}
