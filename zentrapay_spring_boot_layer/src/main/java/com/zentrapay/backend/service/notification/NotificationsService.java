package com.zentrapay.backend.service.notification;

import com.zentrapay.backend.entity.NotificationModel;
import com.zentrapay.backend.repository.NotificationRepository;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.dto.notifications.NotificationDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
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
        // Only read as many rows as this page needs (offset + limit), newest first
        int wanted = Math.max(offset, 0) + Math.max(limit, 1);
        List<NotificationModel> all = notificationRepository.findByUserIdOrderByCreatedAtDesc(userId, PageRequest.of(0, wanted));
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
