package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.SecuritySettingsModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface SecuritySettingsRepository extends JpaRepository<SecuritySettingsModel, UUID> {

    Optional<SecuritySettingsModel> findByUserId(UUID userId);
}
