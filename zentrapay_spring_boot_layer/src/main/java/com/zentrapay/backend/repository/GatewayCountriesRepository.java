package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.GatewayCountryModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface GatewayCountriesRepository extends JpaRepository<GatewayCountryModel, String> {

    @Query("SELECT co FROM GatewayCountryModel co WHERE co.active = :active")
    List<GatewayCountryModel> findByActive(@Param("active") Boolean active);

    Optional<GatewayCountryModel> findFirstByCountryCode(String countryCode);
}