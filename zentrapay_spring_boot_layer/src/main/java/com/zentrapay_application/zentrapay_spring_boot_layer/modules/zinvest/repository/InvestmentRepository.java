package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zinvest.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zinvest.model.InvestmentModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface InvestmentRepository extends JpaRepository<InvestmentModel, UUID> {
    List<InvestmentModel> findByUserId(UUID userId);
    List<InvestmentModel> findByUserIdAndStatus(UUID userId, String status);
    List<InvestmentModel> findByUserIdAndType(UUID userId, String type);
}