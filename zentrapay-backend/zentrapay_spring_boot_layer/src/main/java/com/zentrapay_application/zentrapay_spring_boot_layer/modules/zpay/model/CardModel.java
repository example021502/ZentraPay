package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zpay.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Data
@Table(name = "cards")
public class CardModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "card_id", nullable = false, unique = true)
    private UUID cardId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(nullable = false)
    private String type; // virtual, physical

    @Column(nullable = false, length = 4)
    private String last4;

    @Column(nullable = false)
    private String brand; // Visa, Mastercard, etc.

    @Column(nullable = false)
    private String status = "ACTIVE"; // ACTIVE, INACTIVE, FROZEN

    @Column(name = "expiry_month", nullable = false)
    private Integer expiryMonth;

    @Column(name = "expiry_year", nullable = false)
    private Integer expiryYear;

    @Column(name = "is_nfc_enabled", nullable = false)
    private boolean nfcEnabled = true;

    @Column(name = "is_qr_enabled", nullable = false)
    private boolean qrEnabled = true;

    @CreationTimestamp
    @Column(nullable = false, name = "created_at")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(nullable = false, name = "updated_at")
    private LocalDateTime updatedAt;
}