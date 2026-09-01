package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.NotificationModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

/**
 * Data access for {@code notifications} — in-app notifications per user.
 */
public interface NotificationRepository extends JpaRepository<NotificationModel, UUID> {

    List<NotificationModel> findByUserIdOrderByCreatedAtDesc(UUID userId);
}