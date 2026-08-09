package com.zentrapay_application.zentrapay_spring_boot_layer.modules.secure.dto;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.FraudAlert;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * API contract §16 — {@code GET /api/secure/fraud-alerts}: backed by real
 * {@code fraud_alerts} rows written by {@code PaymentsServices} (and later
 * {@code RemittanceServices}) whenever it flags an anomaly.
 */
public record FraudAlertDTO(
        UUID alertId,
        String alertType,
        String message,
        String severity,
        boolean isResolved,
        LocalDateTime createdAt
) {
    public static FraudAlertDTO from(FraudAlert alert) {
        return new FraudAlertDTO(
                alert.getAlertId(),
                alert.getAlertType(),
                alert.getMessage(),
                alert.getSeverity(),
                alert.isResolved(),
                alert.getCreatedAt()
        );
    }
}
