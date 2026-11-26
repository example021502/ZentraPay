package com.zentrapay.backend.dto.notifications;


import com.zentrapay.backend.service.common.Datatypes;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * GET /api/notifications item shape.
 */
public record NotificationDTO(
        UUID notificationId,
        String title,
        String message,
        Datatypes.NotificationTypes type,
        String referenceId,
        boolean isRead,
        LocalDateTime createdAt
) {
}
