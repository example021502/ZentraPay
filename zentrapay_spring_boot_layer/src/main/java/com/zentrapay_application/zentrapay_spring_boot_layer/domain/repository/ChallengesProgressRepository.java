package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.ChallengesProgressModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ChallengesProgressRepository extends JpaRepository<ChallengesProgressModel, UUID> {

    // Fetch progress timeline for a specific challenge enrollment
    List<ChallengesProgressModel> findByUserChallengeIdOrderByCreatedAtDesc(UUID userChallengeId);
}