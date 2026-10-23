package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.LoginHistoryModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface LoginHistoryRepository extends JpaRepository<LoginHistoryModel, UUID> {
    List<LoginHistoryModel> findByUserIdOrderByCreatedAtDesc(UUID userId);
}
