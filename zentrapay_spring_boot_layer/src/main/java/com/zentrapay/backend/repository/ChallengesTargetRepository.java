package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.ChallengesTargetModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ChallengesTargetRepository extends JpaRepository<ChallengesTargetModel, UUID> {

    // Retrieve targets ordered by tier level
    List<ChallengesTargetModel> findByChallengeIdOrderByTierLevelAsc(UUID challengeId);
}