package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.CountriesModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface CountriesRepository extends JpaRepository<CountriesModel, String> {
    @Query("SELECT c.currencyCode FROM CountriesModel c WHERE c.currencyCode = :currencyCode")
    List<String> getCountryCodesByCurrencyCode(@Param("currencyCode") String currencyCode);
    
}
