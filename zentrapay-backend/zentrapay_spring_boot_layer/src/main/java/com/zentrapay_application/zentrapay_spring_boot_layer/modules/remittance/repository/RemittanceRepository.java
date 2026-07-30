package com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittance.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittance.model.RemittanceModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface RemittanceRepository extends JpaRepository<RemittanceModel, UUID> {
    List<RemittanceModel> findBySenderId(UUID senderId);
    List<RemittanceModel> findBySenderIdAndStatus(UUID senderId, String status);
}