package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.NotificationModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

/**
 * Data access for {@code notifications} — in-app notifications per user.
 */
public interface NotificationRepository extends JpaRepository<NotificationModel, UUID> {

    List<NotificationModel> findByUserIdOrderByCreatedAtDesc(UUID userId, org.springframework.data.domain.Pageable pageable);
}