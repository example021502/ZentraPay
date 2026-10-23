package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.FraudAlert;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface FraudAlertRepository extends JpaRepository<FraudAlert, UUID> {
    List<FraudAlert> findByUserIdOrderByCreatedAtDesc(UUID userId);
}
