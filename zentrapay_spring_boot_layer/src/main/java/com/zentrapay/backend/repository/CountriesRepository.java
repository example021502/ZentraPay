package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.CountriesModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface CountriesRepository extends JpaRepository<CountriesModel, UUID> {
    CountriesModel getCountryByCode(@Param("code") String code);

    @Query("SELECT c.name FROM CountriesModel c WHERE c.code = :code")
    String getCountryNameByCode(String code);

    boolean existsCountryByCode(String countryCode);

}
