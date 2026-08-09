package com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.model.BillPayment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface BillPaymentRepository extends JpaRepository<BillPayment, UUID> {
    List<BillPayment> findByUserIdOrderByCreatedAtDesc(UUID userId);
}
