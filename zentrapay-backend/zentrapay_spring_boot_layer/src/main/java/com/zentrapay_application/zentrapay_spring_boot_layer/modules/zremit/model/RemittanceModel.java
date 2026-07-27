package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zremit.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Data
@Table(name = "remittances")
public class RemittanceModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "remittance_id", nullable = false, unique = true)
    private UUID remittanceId;

    @Column(name = "sender_id", nullable = false)
    private UUID senderId;

    @Column(name = "receiver_id", nullable = false)
    private UUID receiverId;

    @Column(nullable = false, precision = 19, scale = 4)
    private BigDecimal amount;

    @Column(nullable = false, length = 3)
    private String sourceCurrency;

    @Column(nullable = false, length = 3)
    private String destinationCurrency;

    @Column(precision = 19, scale = 4)
    private BigDecimal exchangeRate;

    @Column(precision = 19, scale = 4)
    private BigDecimal fee;

    @Column(nullable = false)
    private String status = "PENDING"; // PENDING, PROCESSING, COMPLETED, FAILED

    @Column(nullable = false)
    private String channel; // MOBILE_MONEY, BANK, CASH

    private String recipientPhoneNumber;

    private String recipientName;

    @Column(nullable = false)
    private String reference;

    @CreationTimestamp
    @Column(nullable = false, name = "created_at")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(nullable = false, name = "updated_at")
    private LocalDateTime updatedAt;
}