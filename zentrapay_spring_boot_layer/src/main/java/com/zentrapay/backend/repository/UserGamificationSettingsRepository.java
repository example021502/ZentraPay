package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.UserGamificationSettingsModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

/** One gameplay-settings row per user (absent row == all defaults). */
public interface UserGamificationSettingsRepository extends JpaRepository<UserGamificationSettingsModel, UUID> {
}
