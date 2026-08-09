package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.model.UserBudget;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface UserBudgetRepository extends JpaRepository<UserBudget, UUID> {
}
