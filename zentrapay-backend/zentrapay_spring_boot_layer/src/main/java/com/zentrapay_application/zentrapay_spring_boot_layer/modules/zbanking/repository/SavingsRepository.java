package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.model.SavingsModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface SavingsRepository extends JpaRepository<SavingsModel, UUID> {
    List<SavingsModel> findByUserId(UUID userId);
    List<SavingsModel> findByUserIdAndStatus(UUID userId, String status);
}