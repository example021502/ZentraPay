package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.model;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "user_wallets")
@Data // Requires Lombok dependency
public class UserWalletsModel {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(nullable = false, name = "wallet_id", unique = true)
    private UUID walletId;

    @Column(nullable = false, name = "user_id")
    private UUID userId;

    @Column(nullable = false, name = "currency_code")
    private String currencyCode;

    @Column(nullable = false, name = "balance")
    private Double balance;

    @Column(nullable = false, name = "is_default")
    private Boolean isDefault;

    @Column(nullable = false, name = "status")
    private String status;

    @Column(nullable = false, name = "created_at")
    private LocalDateTime createdAt;

    @Column(nullable = false, name = "updated_at")
    private LocalDateTime updatedAt;

}