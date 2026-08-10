package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.model.ChallengeModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.model.JoinedChallenges;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ChallengeRepository extends JpaRepository<ChallengeModel, UUID> {
    List<ChallengeModel> findByStatus(String status);
    List<JoinedChallenges> findByUserId(UUID userId);
    ChallengeModel getChallengeByChallengeId(UUID challengeId);
    List<ChallengeModel> findByCategoryAndStatus(String category, String status);
}