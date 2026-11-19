package com.zentrapay.backend.entity;

import com.zentrapay.backend.service.common.Datatypes;
import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Shared across modules that can flag anomalies against a user's activity
 * (payments, remittance, zvoice, ...) — every such module writes rows here
 * via this one entity rather than declaring its own fraud table.
 */
@Entity
@Data
@Table(name = "alerts")
public class AlertsModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "name", nullable = false, length = 40)
    private String name;

    @Column(name = "message", nullable = false)
    private String message;

    @Column(nullable = false, length = 20)
    private Datatypes.AlertLevel severity = Datatypes.AlertLevel.LOW; // LOW, MEDIUM, HIGH, CRITICAL

    @Column(name = "is_resolved", nullable = false)
    private boolean isResolved = false;

    @Column(name = "related_transaction_id")
    private UUID relatedTransactionId;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
}
