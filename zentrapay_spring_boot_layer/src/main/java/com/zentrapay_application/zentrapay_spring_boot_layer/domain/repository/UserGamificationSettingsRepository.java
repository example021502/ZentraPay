package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserGamificationSettingsModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

/** One gameplay-settings row per user (absent row == all defaults). */
public interface UserGamificationSettingsRepository extends JpaRepository<UserGamificationSettingsModel, UUID> {
}
