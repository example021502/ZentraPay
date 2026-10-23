package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.ChallengesProgressModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ChallengesProgressRepository extends JpaRepository<ChallengesProgressModel, UUID> {

    // Fetch progress timeline for a specific challenge enrollment
    List<ChallengesProgressModel> findByUserChallengeIdOrderByCreatedAtDesc(UUID userChallengeId);
}