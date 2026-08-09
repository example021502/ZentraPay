package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.model.UserRewardBalance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface UserRewardBalanceRepository extends JpaRepository<UserRewardBalance, UUID> {
}
