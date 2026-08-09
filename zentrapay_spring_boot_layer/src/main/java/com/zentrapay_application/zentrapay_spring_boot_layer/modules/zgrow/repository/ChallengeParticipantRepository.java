package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.model.ChallengeParticipant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ChallengeParticipantRepository extends JpaRepository<ChallengeParticipant, UUID> {
    long countByChallengeId(UUID challengeId);
    Optional<ChallengeParticipant> findByChallengeIdAndUserId(UUID challengeId, UUID userId);
    List<ChallengeParticipant> findByUserId(UUID userId);
    boolean existsByChallengeIdAndUserId(UUID challengeId, UUID userId);
}
