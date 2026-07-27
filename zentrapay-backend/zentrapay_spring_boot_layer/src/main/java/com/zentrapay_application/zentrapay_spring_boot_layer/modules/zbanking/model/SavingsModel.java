package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Data
@Table(name = "savings_accounts")
public class SavingsModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "savings_id", nullable = false, unique = true)
    private UUID savingsId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(nullable = false)
    private String savingsName;

    @Column(nullable = false, precision = 19, scale = 4)
    private BigDecimal balance;

    @Column(nullable = false, length = 3)
    private String currency;

    private String description;

    private LocalDate targetDate;

    @Column(precision = 19, scale = 4)
    private BigDecimal targetAmount;

    @Column(nullable = false)
    private String status = "ACTIVE";

    @CreationTimestamp
    @Column(nullable = false, name = "created_at")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(nullable = false, name = "updated_at")
    private LocalDateTime updatedAt;
}