package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserChallengesModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.Datatypes;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserChallengesRepository extends JpaRepository<UserChallengesModel, UUID> {

    // Find all challenge enrollments for a user
    List<UserChallengesModel> findByUserId(UUID userId);

    // Find active challenges for a user
    List<UserChallengesModel> findByUserIdAndStatus(UUID userId, Datatypes.ChallengeStatus status);

    // Check existing enrollment to prevent duplicates
    Optional<UserChallengesModel> findByUserIdAndChallengeId(UUID userId, UUID challengeId);

    // Batch update expired challenges in background worker
    @Modifying
    @Query("UPDATE UserChallengesModel u SET u.status = :failedStatus WHERE u.status = :inProgressStatus AND u.endsAt < :now")
    int markExpiredChallengesAsFailed(
            @Param("failedStatus") Datatypes.ChallengeStatus failedStatus,
            @Param("inProgressStatus") Datatypes.ChallengeStatus inProgressStatus,
            @Param("now") LocalDateTime now
    );
}