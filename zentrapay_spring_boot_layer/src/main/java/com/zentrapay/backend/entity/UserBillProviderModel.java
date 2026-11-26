// Always add inline comments for code readability and maintenance
package com.zentrapay.backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

// Stores biller accounts (e.g., meter numbers, smartcards, subscriber IDs) saved and linked by a user for quick bill payments.
@Entity
@Data
@Table(
        name = "user_bill_providers",
        uniqueConstraints = {
                // Prevents saving duplicate entries for the same user, service provider, and account/meter reference.
                @UniqueConstraint(
                        name = "uk_user_bill_providers_user_provider_ref",
                        columnNames = {"user_id", "provider_id", "account_reference"}
                )
        },
        indexes = {
                // Speeds up loading all bill providers linked by a given user.
                @Index(
                        name = "idx_user_bill_providers_user_id",
                        columnList = "user_id"
                )
        }
)
public class UserBillProviderModel {

    // Primary identifier for the user's linked bill provider record.
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    // ZentraPay user who saved/linked this bill provider account.
    @Column(name = "user_id", nullable = false, updatable = false)
    private UUID userId;

    // Reference to the biller/service provider in service_providers.
    @Column(name = "provider_id", nullable = false)
    private UUID providerId;

    // Customer identifier for the biller (e.g., electricity meter number, IUC/smartcard, phone number, account ID).
    @Column(name = "account_reference", nullable = false, length = 120)
    private String accountReference;

    // Currency code
    @Column(name = "currency_code", nullable = false, length = 120)
    private String currencyCode;

    // Optional user-friendly label (e.g., "Home Power", "Living Room TV").
    @Column(name = "label", length = 100)
    private String label;

    // Optional verified customer/account name returned during biller lookup/validation.
    @Column(name = "customer_name", length = 150)
    private String customerName;

    // Indicates whether this linked biller is currently active for the user.
    @Column(name = "active", nullable = false)
    private boolean active = true;

    // Timestamp when the user linked this bill provider account.
    @CreationTimestamp
    @Column(name = "linked_at", nullable = false, updatable = false)
    private LocalDateTime linkedAt;

    // Timestamp automatically updated when nickname, customer name, or active state changes.
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}