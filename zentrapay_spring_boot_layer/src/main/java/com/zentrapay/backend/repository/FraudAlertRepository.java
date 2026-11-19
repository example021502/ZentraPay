package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.AlertsModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface FraudAlertRepository extends JpaRepository<AlertsModel, UUID> {
    List<AlertsModel> findByUserIdOrderByCreatedAtDesc(UUID userId);
}
