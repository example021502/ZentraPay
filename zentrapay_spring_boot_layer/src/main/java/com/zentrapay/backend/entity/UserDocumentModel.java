package com.zentrapay.backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

// Tracks which legal/compliance document versions a user has accepted and when.
@Entity
@Data
@Table(
        name = "user_documents",
        uniqueConstraints = {
                // Prevents duplicate acceptance records for the same user and document version.
                @UniqueConstraint(
                        name = "uk_user_documents_user_document",
                        columnNames = {"user_id", "document_id"}
                )
        },
        indexes = {
                // Speeds up lookups of all documents accepted by a specific user.
                @Index(
                        name = "idx_user_documents_user_id",
                        columnList = "user_id"
                ),
                // Speeds up checks for whether a user accepted a specific document.
                @Index(
                        name = "idx_user_documents_document_id",
                        columnList = "document_id"
                )
        }
)
public class UserDocumentModel {

    // Primary identifier for the user acceptance record.
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    // ID of the user who accepted the document.
    @Column(name = "user_id", nullable = false, updatable = false)
    private UUID userId;

    // ID of the specific document version in the documents table that the user accepted.
    @Column(name = "document_id", nullable = false, updatable = false)
    private UUID documentId;

    // Optional client IP address captured at the time of acceptance for compliance auditing.
    @Column(name = "ip_address", length = 64, updatable = false)
    private String ipAddress;

    // Optional client/device user-agent string captured at acceptance.
    @Column(name = "user_agent", length = 255, updatable = false)
    private String userAgent;

    // Timestamp when the user accepted the document.
    @CreationTimestamp
    @Column(name = "accepted_at", nullable = false, updatable = false)
    private LocalDateTime acceptedAt;
}