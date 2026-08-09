package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

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
@Table(name = "fraud_alerts")
public class FraudAlert {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "alert_id", nullable = false)
    private UUID alertId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "alert_type", nullable = false, length = 40)
    private String alertType;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String message;

    @Column(nullable = false, length = 20)
    private String severity = "LOW"; // LOW, MEDIUM, HIGH, CRITICAL

    @Column(name = "is_resolved", nullable = false)
    private boolean isResolved;

    @Column(name = "related_transaction_id")
    private UUID relatedTransactionId;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
}
