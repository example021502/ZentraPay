package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.UserBudgetModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface UserBudgetRepository extends JpaRepository<UserBudgetModel, UUID> {
    Optional<UserBudgetModel> findByUserIdAndCurrencyCode(UUID userId, String currencyCode);
}
