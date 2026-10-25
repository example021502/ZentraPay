package com.zentrapay.backend.dto.notifications;


import java.time.LocalDateTime;
import java.util.UUID;

/** GET /api/notifications item shape. */
public record NotificationDTO(
        UUID notificationId,
        String title,
        String message,
        String type,
        String referenceId,
        boolean isRead,
        LocalDateTime createdAt
) {
}
