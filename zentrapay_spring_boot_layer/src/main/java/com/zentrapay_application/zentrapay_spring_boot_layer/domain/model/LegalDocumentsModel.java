package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * The single canonical mapping of the "users" table. Every module that
 * needs a user (payments, search, transactions, ...) reads/writes this
 * entity — no module should declare its own parallel @Entity for "users".
 */
@Entity
@Data
@Table(name = "legal_documents")
public class LegalDocumentsModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "document_id", nullable = false, unique = true)
    private UUID documentId;

    @Column(name = "document_type", nullable = false)
    private String documentType;

    @Column(name = "document_version", nullable = false)
    private String documentVersion;

    @Column(name = "title", nullable = false, unique = true)
    private String title;

    @Column(name = "file_url", nullable = false, unique = true)
    private String fileUrl;

    @Column(name = "content_hash", nullable = false)
    private String contentHash;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive;

    @CreationTimestamp
    @Column(name = "effective_date", nullable = false)
    private LocalDateTime effectiveDate;

    @UpdateTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

}
