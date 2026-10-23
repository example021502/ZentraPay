package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.MobileMoneyProvidersModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface MobileMoneyRepository extends JpaRepository<MobileMoneyProvidersModel, UUID> {

    // Used by the provider sync job to upsert instead of duplicating rows.
    Optional<MobileMoneyProvidersModel> findByGlobalCode(String globalCode);
}
