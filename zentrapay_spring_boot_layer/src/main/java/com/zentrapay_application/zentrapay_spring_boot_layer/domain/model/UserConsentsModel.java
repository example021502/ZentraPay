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
@Table(name = "user_consents")
public class UserConsentsModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "consent_id", nullable = false, unique = true)
    private UUID consentId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "document_id", nullable = false)
    private UUID documentId;

    @Column(name = "ip_address", nullable = false, unique = true, length = 20)
    private String ipAddress;

    @CreationTimestamp
    @Column(name = "accepted_at", nullable = false)
    private LocalDateTime acceptedAt;
}
