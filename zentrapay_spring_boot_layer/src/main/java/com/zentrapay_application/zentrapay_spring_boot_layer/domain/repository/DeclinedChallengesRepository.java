package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.DeclinedChallengesModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface DeclinedChallengesRepository extends JpaRepository<DeclinedChallengesModel, UUID> {

    // All challenges a user has opted out of
    List<DeclinedChallengesModel> findByUserId(UUID userId);

    // Declines are unique per (user, challenge) — used when re-checking before insert
    Optional<DeclinedChallengesModel> findByUserIdAndChallengeId(UUID userId, UUID challengeId);
}
