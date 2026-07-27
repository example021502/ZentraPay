package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zvoice.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zvoice.model.VoiceCommandModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface VoiceCommandRepository extends JpaRepository<VoiceCommandModel, UUID> {
    List<VoiceCommandModel> findByUserId(UUID userId);
    List<VoiceCommandModel> findByUserIdAndLanguage(UUID userId, String language);
    List<VoiceCommandModel> findByUserIdAndFraudAlert(UUID userId, boolean fraudAlert);
}