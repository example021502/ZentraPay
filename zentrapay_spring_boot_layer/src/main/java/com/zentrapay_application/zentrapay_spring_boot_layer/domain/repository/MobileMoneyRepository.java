package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.MobileMoneyProvidersModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface MobileMoneyRepository extends JpaRepository<MobileMoneyProvidersModel, UUID> {

    // Used by the provider sync job to upsert instead of duplicating rows.
    Optional<MobileMoneyProvidersModel> findByGlobalCode(String globalCode);
}
