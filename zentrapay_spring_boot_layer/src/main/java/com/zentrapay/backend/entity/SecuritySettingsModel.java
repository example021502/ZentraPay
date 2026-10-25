package com.zentrapay.backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * One row per user: the security toggles and app preferences behind the
 * Settings screen (biometric login, two-factor, fraud protection, dark mode,
 * notification switches). Created with defaults the first time it is read.
 */
@Entity
@Data
@Table(name = "security_settings")
public class SecuritySettingsModel {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "settings_id", nullable = false)
    private UUID settingsId;

    @Column(name = "user_id", nullable = false, unique = true)
    private UUID userId;

    @Column(name = "biometric_enabled", nullable = false)
    private boolean biometricEnabled = false;

    @Column(name = "biometric_type", length = 20)
    private String biometricType;

    @Column(name = "two_factor_enabled", nullable = false)
    private boolean twoFactorEnabled = false;

    @Column(name = "two_factor_method", length = 20)
    private String twoFactorMethod;

    @Column(name = "fraud_protection_enabled", nullable = false)
    private boolean fraudProtectionEnabled = true;

    @Column(name = "dark_mode", nullable = false)
    private boolean darkMode = false;

    @Column(name = "push_notifications_enabled", nullable = false)
    private boolean pushNotificationsEnabled = true;

    @Column(name = "transaction_alerts_enabled", nullable = false)
    private boolean transactionAlertsEnabled = true;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
