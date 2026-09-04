package com.zentrapay_application.zentrapay_spring_boot_layer.modules.notifications.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.notifications.dto.NotificationDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.notifications.service.NotificationsService;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.AuthenticatedUser;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * In-app notifications — backs the home screen's notification-bell overlay.
 */
@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationsController {

    private final NotificationsService notificationsService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<NotificationDTO>>> list(
            @CurrentUser AuthenticatedUser user,
            @RequestParam(defaultValue = "50") int limit,
            @RequestParam(defaultValue = "0") int offset) {
        List<NotificationDTO> notifications = notificationsService.list(user.getUserId(), limit, offset);
        return ResponseEntity.ok(ApiResponse.success(notifications, "Notifications retrieved"));
    }

    @PatchMapping("/{notificationId}/read")
    public ResponseEntity<ApiResponse<NotificationDTO>> markRead(
            @CurrentUser AuthenticatedUser user,
            @PathVariable UUID notificationId) {
        NotificationDTO notification = notificationsService.markRead(user.getUserId(), notificationId);
        return ResponseEntity.ok(ApiResponse.success(notification, "Notification marked read"));
    }
}
