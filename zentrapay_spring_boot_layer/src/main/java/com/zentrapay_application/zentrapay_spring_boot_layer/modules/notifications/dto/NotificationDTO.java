package com.zentrapay_application.zentrapay_spring_boot_layer.modules.notifications.dto;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.Datatypes;

import java.time.LocalDateTime;
import java.util.UUID;

/** GET /api/notifications item shape. */
public record NotificationDTO(
        UUID notificationId,
        String title,
        String message,
        Datatypes.TransactionType type,
        String referenceId,
        boolean isRead,
        LocalDateTime createdAt
) {
}
