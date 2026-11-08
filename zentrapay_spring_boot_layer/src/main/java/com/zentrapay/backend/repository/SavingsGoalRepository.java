package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.SavingsGoalModel;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import org.springframework.data.domain.Pageable;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface SavingsGoalRepository extends JpaRepository<SavingsGoalModel, UUID> {

    List<SavingsGoalModel> findByUserIdOrderByCreatedAtDesc(UUID userId);

    // Deposits and withdrawals read the goal WITH a lock so two taps at once cannot overdraw it
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT g FROM SavingsGoalModel g WHERE g.goalId = :goalId AND g.userId = :userId")
    Optional<SavingsGoalModel> findOwnedForUpdate(@Param("goalId") UUID goalId, @Param("userId") UUID userId);

    // The background job: goals whose automatic save is due. Only ids - each one is re-read WITH a lock before it is touched
    @Query("SELECT g.goalId FROM SavingsGoalModel g WHERE g.autoEnabled = true AND g.autoNextRun <= :now ORDER BY g.autoNextRun")
    List<UUID> findDueAutoSaveIds(@Param("now") LocalDateTime now, Pageable pageable);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT g FROM SavingsGoalModel g WHERE g.goalId = :goalId")
    Optional<SavingsGoalModel> findByIdForUpdate(@Param("goalId") UUID goalId);
}
