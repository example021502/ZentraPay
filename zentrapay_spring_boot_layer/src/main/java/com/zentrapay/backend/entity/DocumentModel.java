package com.zentrapay.backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

// Stores versioned legal and compliance documents mapped to platform services (e.g., CORE, INVESTMENTS).
@Entity
@Data
@Table(
        name = "documents",
        uniqueConstraints = {
                // Ensures each document type/key can only have one record per version number.
                @UniqueConstraint(
                        name = "uk_documents_doc_key_version",
                        columnNames = {"doc_key", "version"}
                )
        },
        indexes = {
                // Speeds up frontend queries for active documents belonging to a specific service scope.
                @Index(
                        name = "idx_documents_service_active",
                        columnList = "service_code, is_active"
                )
        }
)
public class DocumentModel {

    // Primary identifier for the legal document version.
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    // Stable slug/identifier across versions (e.g., "terms_of_use", "privacy_policy", "investment_risk_disclosure").
    @Column(name = "doc_key", nullable = false, length = 64)
    private String docKey;

    // Service or module scope that requires this document (e.g., "CORE" for onboarding/general, "INVESTMENTS" for ZInvest).
    @Column(name = "service_code", nullable = false, length = 32)
    private String serviceCode = "CORE";

    // Incremental version number (1, 2, 3...) to avoid floating-point precision issues.
    @Column(name = "version", nullable = false)
    private Integer version;

    // Human-readable title displayed on the frontend (not globally unique so v1 and v2 can share a title).
    @Column(name = "title", nullable = false, length = 150)
    private String title;

    // Hosted URL or storage path to the document file/content.
    @Column(name = "file_url", nullable = false, unique = true)
    private String fileUrl;

    // SHA-256 (or similar) hash of the document content for tamper detection and audit proof.
    @Column(name = "content_hash", nullable = false, length = 64)
    private String contentHash;

    // Indicates whether this version is the currently enforced version for its docKey/serviceCode.
    @Column(name = "is_active", nullable = false)
    private boolean isActive = true;

    // Legal date/time when this document version takes effect.
    @Column(name = "effective_date", nullable = false)
    private LocalDateTime effectiveDate;

    // Timestamp when this record was inserted into the database.
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // Timestamp automatically updated whenever the row changes (e.g., toggling isActive).
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}