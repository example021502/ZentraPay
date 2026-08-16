package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.CountriesModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.SupportedCountriesModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface SupportedCountriesRepository extends JpaRepository<SupportedCountriesModel, String> {

    @Query("SELECT co FROM SupportedCountriesModel co WHERE co.active = :active")
    List<SupportedCountriesModel> findByActive(@Param("active") Boolean active);

    Optional<SupportedCountriesModel> findFirstByCountryCode(String countryCode);
}
