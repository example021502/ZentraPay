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

    // Every currency a payment can be made in: the default currency of each active country
    @Query("SELECT DISTINCT UPPER(co.defaultCurrency) FROM GatewayCountryModel co WHERE co.active = true AND co.defaultCurrency <> ''")
    List<String> findActiveDefaultCurrencies();

    // The active countries that use a currency as their default (a shared currency like XOF has several)
    @Query("SELECT co FROM GatewayCountryModel co WHERE co.active = true AND UPPER(co.defaultCurrency) = UPPER(:currency)")
    List<GatewayCountryModel> findActiveByDefaultCurrency(@Param("currency") String currency);
}
