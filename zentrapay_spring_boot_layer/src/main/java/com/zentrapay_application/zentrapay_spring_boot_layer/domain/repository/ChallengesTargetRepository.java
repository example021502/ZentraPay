package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.ChallengesTargetModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ChallengesTargetRepository extends JpaRepository<ChallengesTargetModel, UUID> {

    // Retrieve targets ordered by tier level
    List<ChallengesTargetModel> findByChallengeIdOrderByTierLevelAsc(UUID challengeId);
}