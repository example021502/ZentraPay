package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.VoiceCommandModel;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface VoiceCommandRepository extends JpaRepository<VoiceCommandModel, UUID> {

    // The user's ZVoice history, newest first
    List<VoiceCommandModel> findByUserIdOrderByCreatedAtDesc(UUID userId, Pageable pageable);

    // Voice instructions that looked like fraud
    List<VoiceCommandModel> findByUserIdAndFraudAlertTrueOrderByCreatedAtDesc(UUID userId);
}
