package com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittance.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittance.model.Remittance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface RemittanceRepository extends JpaRepository<Remittance, UUID> {
    List<Remittance> findBySenderIdOrderByCreatedAtDesc(UUID senderId);
    boolean existsBySenderIdAndRecipientPhoneNumber(UUID senderId, String recipientPhoneNumber);
}
