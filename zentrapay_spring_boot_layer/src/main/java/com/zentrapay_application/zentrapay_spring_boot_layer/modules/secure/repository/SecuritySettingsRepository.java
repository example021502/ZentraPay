package com.zentrapay_application.zentrapay_spring_boot_layer.modules.secure.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.secure.model.SecuritySettingsModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface SecuritySettingsRepository extends JpaRepository<SecuritySettingsModel, UUID> {
    Optional<SecuritySettingsModel> findByUserId(UUID userId);
}
