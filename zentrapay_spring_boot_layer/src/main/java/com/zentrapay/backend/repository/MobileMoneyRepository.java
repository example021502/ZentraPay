package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.MobileMoneyProvidersModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface MobileMoneyRepository extends JpaRepository<MobileMoneyProvidersModel, UUID> {

    // Used by the provider sync job to upsert instead of duplicating rows.
    Optional<MobileMoneyProvidersModel> findByGlobalCode(String globalCode);

    // A network is identified by its code AND country ("MTN" exists in several countries)
    Optional<MobileMoneyProvidersModel> findByGlobalCodeAndCountryCode(String globalCode, String countryCode);

    // Search / pickers: active networks of one country
    List<MobileMoneyProvidersModel> findByCountryCodeIgnoreCaseAndActiveTrueOrderByName(String countryCode);

    // Search / pickers: active networks of every country except one
    List<MobileMoneyProvidersModel> findByCountryCodeNotIgnoreCaseAndActiveTrueOrderByName(String countryCode);
}
