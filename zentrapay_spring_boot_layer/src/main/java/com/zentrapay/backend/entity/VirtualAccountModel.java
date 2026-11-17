package com.zentrapay.backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Canonical fiat wallet — consolidates the old fiat_currency_accounts /
 * fiat_currencies / user_wallets (x2 conflicting mappings).
 */
@Entity
@Data
@Table(name = "virtual_accounts", uniqueConstraints = {
        @UniqueConstraint(
                name = "uk_user_currency", // Optional: explicit constraint name in the database
                columnNames = {"user_id", "currency"} // Must match your database column names, not Java property names
        )
})
public class VirtualAccountModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, unique = true)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "merchant_reference", nullable = false, unique = true)
    private String merchantReference;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @Column(name = "status", nullable = false)
    private String status;

    @Column(name = "account_type", nullable = false)
    private String accountType;

    @Column(name = "account_number", nullable = false)
    private String accountNumber;

    @Column(name = "bankName", nullable = false)
    private String bankName;

    @Column(name = "label", nullable = false)
    private String label;

    @Column(name = "email", nullable = false)
    private String email;

    @Column(name = "balance", nullable = false)
    private BigDecimal balance;

    @Column(name = "is_active", nullable = false)
    private boolean isActive;

    @Column(name = "is_default", nullable = false)
    private boolean isDefault;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
