package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.SavingsGoalModel;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface SavingsGoalRepository extends JpaRepository<SavingsGoalModel, UUID> {

    List<SavingsGoalModel> findByUserIdOrderByCreatedAtDesc(UUID userId);

    // Deposits and withdrawals read the goal WITH a lock so two taps at once cannot overdraw it
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT g FROM SavingsGoalModel g WHERE g.goalId = :goalId AND g.userId = :userId")
    Optional<SavingsGoalModel> findOwnedForUpdate(@Param("goalId") UUID goalId, @Param("userId") UUID userId);
}
