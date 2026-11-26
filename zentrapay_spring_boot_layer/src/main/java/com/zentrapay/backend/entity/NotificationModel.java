package com.zentrapay.backend.entity;

import com.zentrapay.backend.service.common.Datatypes;
import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

// In-app notification record surfaced to a user (e.g., transfer outcomes, loan updates, system alerts).
@Entity
@Data
@Table(
        name = "notifications",
        indexes = {
                // Speeds up unread badge counts and filtering unread alerts per user.
                @Index(
                        name = "idx_notifications_user_read",
                        columnList = "user_id, is_read"
                ),
                // Speeds up paginated inbox feeds ordered from newest to oldest.
                @Index(
                        name = "idx_notifications_user_created",
                        columnList = "user_id, created_at"
                )
        }
)
public class NotificationModel {

    // Primary identifier for the notification.
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    // Recipient user ID.
    @Column(name = "user_id", nullable = false, updatable = false)
    private UUID userId;

    // Short headline displayed in the notification list or push banner.
    @Column(name = "title", nullable = false, length = 120)
    private String title;

    // Detailed notification body text.
    @Column(name = "message", nullable = false, length = 1000)
    private String message;

    // Event category (e.g., P2P_TRANSFER, CASH_OUT_BANK, LOAN_APPROVED, SYSTEM).
    @Column(name = "type", nullable = false, length = 30, updatable = false)
    private String type;

    // Correlated domain reference (e.g., zp_... transaction ref or loan ID) for deep-linking.
    @Column(name = "reference_id", length = 100, updatable = false)
    private String referenceId;

    // Tracks whether the user has read the notification.
    @Column(name = "is_read", nullable = false)
    private Boolean isRead = false;

    // Timestamp when the notification was created.
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // Timestamp automatically updated when the notification state changes (e.g., marked read).
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}