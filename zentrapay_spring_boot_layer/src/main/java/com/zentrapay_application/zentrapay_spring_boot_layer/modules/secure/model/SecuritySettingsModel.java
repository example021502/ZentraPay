package com.zentrapay_application.zentrapay_spring_boot_layer.modules.secure.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Data
@Table(name = "security_settings")
public class SecuritySettingsModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "settings_id", nullable = false, unique = true)
    private UUID settingsId;

    @Column(name = "user_id", nullable = false, unique = true)
    private UUID userId;

    @Column(name = "biometric_enabled", nullable = false)
    private boolean biometricEnabled = false;

    @Column(name = "biometric_type", length = 30)
    private String biometricType;

    @Column(name = "two_factor_enabled", nullable = false)
    private boolean twoFactorEnabled = false;

    @Column(name = "two_factor_method", length = 30)
    private String twoFactorMethod;

    @Column(name = "fraud_protection_enabled", nullable = false)
    private boolean fraudProtectionEnabled = true;

    @CreationTimestamp
    @Column(nullable = false, name = "created_at")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(nullable = false, name = "updated_at")
    private LocalDateTime updatedAt;
}
