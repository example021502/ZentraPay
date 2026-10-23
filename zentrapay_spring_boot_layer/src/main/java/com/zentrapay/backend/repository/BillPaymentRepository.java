package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.BillPaymentModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface BillPaymentRepository extends JpaRepository<BillPaymentModel, UUID> {

    // The 50 most recent bill payments of a user, newest first
    List<BillPaymentModel> findTop50ByUserIdOrderByCreatedAtDesc(UUID userId);
}
