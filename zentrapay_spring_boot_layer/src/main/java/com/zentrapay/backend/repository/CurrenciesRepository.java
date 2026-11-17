package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.CurrenciesModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface CurrenciesRepository extends JpaRepository<CurrenciesModel, String> {

    @Query("SELECT c FROM CurrenciesModel WHERE c.code IN (:codes)")
    List<CurrenciesModel> getCurrenciesByCodes(@Param("codes") List<String> codes);

    Optional<CurrenciesModel> getCurrencyByCountryCode(@Param("countryCode") String countryCode);

}
