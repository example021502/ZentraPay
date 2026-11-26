// Always add inline comments for code readability and maintenance
package com.zentrapay.backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

// Stores audit records of legal/policy/consent documents accepted by a user along with network and device context.
@Entity
@Data
@Table(
        name = "user_consents",
        indexes = {
                // Speeds up checking whether a user has accepted a specific consent/policy document.
                @Index(
                        name = "idx_user_consents_user_document",
                        columnList = "user_id, document_id"
                )
        }
)
public class UserConsentsModel {

    // Primary identifier for the consent acceptance record.
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    // User who granted or accepted the consent.
    @Column(name = "user_id", nullable = false, updatable = false)
    private UUID userId;

    // Identifier of the consent/terms/privacy document version accepted by the user.
    @Column(name = "document_id", nullable = false, updatable = false)
    private UUID documentId;

    // Client IP address recorded at consent time (supports both IPv4 and IPv6; non-unique across users/events).
    @Column(name = "ip_address", nullable = false, length = 45, updatable = false)
    private String ipAddress;

    // User device and client metadata at consent time (e.g., OS, model, app version, or user agent).
    @Column(name = "device_info", length = 255, updatable = false)
    private String deviceInfo;

    // Timestamp when the user accepted the consent document.
    @CreationTimestamp
    @Column(name = "accepted_at", nullable = false, updatable = false)
    private LocalDateTime acceptedAt;
}