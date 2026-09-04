package com.zentrapay_application.zentrapay_spring_boot_layer.modules.notifications.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.NotificationModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.NotificationRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ResourceNotFoundException;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.notifications.dto.NotificationDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * In-app notifications — GET/PATCH {@code /api/notifications}. Backed by
 * the {@code notifications} table ({@link NotificationModel}) that
 * payment/webhook flows already write to.
 */
@Service
@RequiredArgsConstructor
public class NotificationsService {

    private final NotificationRepository notificationRepository;

    @Transactional(readOnly = true)
    public List<NotificationDTO> list(UUID userId, int limit, int offset) {
        List<NotificationModel> all = notificationRepository.findByUserIdOrderByCreatedAtDesc(userId);
        return all.stream()
                .skip(Math.max(offset, 0))
                .limit(Math.max(limit, 1))
                .map(this::toDTO)
                .toList();
    }

    @Transactional
    public NotificationDTO markRead(UUID userId, UUID notificationId) {
        NotificationModel notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new ResourceNotFoundException("Notification not found"));
        if (!notification.getUserId().equals(userId)) {
            // Comment: don't leak whether the id exists for another user —
            // same 404 as "not found".
            throw new ResourceNotFoundException("Notification not found");
        }
        if (!Boolean.TRUE.equals(notification.getIsRead())) {
            notification.setIsRead(true);
            notification = notificationRepository.save(notification);
        }
        return toDTO(notification);
    }

    private NotificationDTO toDTO(NotificationModel n) {
        return new NotificationDTO(
                n.getNotificationId(),
                n.getTitle(),
                n.getMessage(),
                n.getType(),
                n.getReferenceId(),
                Boolean.TRUE.equals(n.getIsRead()),
                n.getCreatedAt()
        );
    }
}
