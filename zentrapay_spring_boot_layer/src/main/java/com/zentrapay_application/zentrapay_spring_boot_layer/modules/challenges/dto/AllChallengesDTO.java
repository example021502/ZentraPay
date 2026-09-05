package com.zentrapay_application.zentrapay_spring_boot_layer.modules.challenges.dto;

import java.time.LocalDateTime;
import java.util.UUID;

/** GET /api/notifications item shape. */
public record AllChallengesDTO(
        UUID notificationId,
        String title,
        String message,
        String type,
        String referenceId,
        boolean isRead,
        LocalDateTime createdAt
) {
}
