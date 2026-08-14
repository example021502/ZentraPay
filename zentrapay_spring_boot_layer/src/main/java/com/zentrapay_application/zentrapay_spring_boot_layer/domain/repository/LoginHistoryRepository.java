package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.LoginHistoryModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface LoginHistoryRepository extends JpaRepository<LoginHistoryModel, UUID> {
    List<LoginHistoryModel> findByUserIdOrderByCreatedAtDesc(UUID userId);
}
