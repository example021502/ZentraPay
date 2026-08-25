package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserBankModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public interface UserBankRepository extends JpaRepository<UserBankModel, UUID> {
    @Query("SELECT ub.bankId FROM UserBankModel ub WHERE ub.userId = :userId")
    List<UUID> getBankIdsByUserId(@Param("userId") UUID userId);

    @Query("SELECT ub.balance FROM UserBankModel ub WHERE ub.userId = :userId AND ub.bankId = :bankId")
    UserBankModel getBalanceByUserIdAndBankId(@Param("userId") UUID userId, @Param("bankId") UUID bankId);
}
