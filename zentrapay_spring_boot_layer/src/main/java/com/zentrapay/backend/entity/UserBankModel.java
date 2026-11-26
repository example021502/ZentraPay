// Always add inline comments for code readability and maintenance
package com.zentrapay.backend.entity;

import com.zentrapay.backend.service.common.Datatypes;
import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

// Stores external bank accounts linked by a user via open banking (e.g., AfriLink) for balance viewing and funding.
@Entity
@Data
@Table(
        name = "user_bank",
        uniqueConstraints = {
                // Prevents linking the exact same open-banking provider account multiple times.
                @UniqueConstraint(
                        name = "uk_user_bank_provider_account",
                        columnNames = {"provider", "provider_account_id"}
                )
        },
        indexes = {
                // Speeds up loading a user's linked bank accounts filtered by connection status.
                @Index(
                        name = "idx_user_bank_user_status",
                        columnList = "user_id, connection_status"
                )
        }
)
public class UserBankModel {

    // Primary identifier for the user's linked bank account record.
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    // Owner user ID who linked this external bank account.
    @Column(name = "user_id", nullable = false, updatable = false)
    private UUID userId;

    // Cached external account balance fetched from the open-banking provider (not an internal ledger balance).
    @Column(name = "balance", nullable = false, precision = 19, scale = 4)
    private BigDecimal balance = BigDecimal.ZERO;

    // Timestamp when the external bank balance was last refreshed from the provider.
    @Column(name = "balance_synced_at")
    private LocalDateTime balanceSyncedAt;

    // Optional reference to ZentraPay's internal banks catalog row.
    @Column(name = "bank_id")
    private UUID bankId;

    // Last 4 digits of the linked bank account number for UI display.
    @Column(name = "last_digits", nullable = false, length = 4)
    private String lastDigits = "";

    // Open-banking link state (e.g., active, disconnected, reauth_required).
    @Column(name = "connection_status", nullable = false, length = 30)
    private Datatypes.UserBankConnectionStatus connectionStatus = Datatypes.UserBankConnectionStatus.ACTIVE;

    // Provider session/connection identifier used to refresh balances or initiate debits.
    @Column(name = "connection_id", nullable = false, length = 128)
    private String connectionId;

    // Marks the user's primary linked bank account (enforced at DB level via partial unique index uq_user_bank_primary_per_user).
    @Column(name = "is_primary", nullable = false)
    private Boolean primary = false;

    // Optional user-chosen nickname for the linked account (e.g., "Salary"); falls back to institution/bank name when null.
    @Column(name = "link_label", length = 120)
    private String linkLabel;

    // Open-banking aggregator/provider that verified the link (e.g., AFRILINK).
    @Column(name = "provider", nullable = false, length = 30, updatable = false)
    private String provider = "AFRILINK";

    // Opaque account identifier assigned by the open-banking provider (e.g., AfriLink data.id).
    @Column(name = "provider_account_id", length = 128)
    private String providerAccountId;

    // Provider-specific institution/bank identifier.
    @Column(name = "institution_id", length = 128)
    private String institutionId;

    // Human-readable name of the external bank/institution.
    @Column(name = "institution_name", length = 180)
    private String institutionName;

    // Bank account classification reported by the provider (e.g., SAVINGS, CURRENT, CHECKING).
    @Column(name = "account_type", length = 40)
    private String accountType;

    // ISO 4217 currency code of the linked bank account (e.g., NGN, KES, GHS).
    @Column(name = "currency_code", length = 3)
    private String currencyCode;

    // ISO country code of the linked bank account.
    @Column(name = "country_code", length = 3)
    private String countryCode;

    // Timestamp when the user initially linked this bank account.
    @CreationTimestamp
    @Column(name = "linked_at", nullable = false, updatable = false)
    private LocalDateTime linkedAt;

    // Timestamp automatically updated when balance, status, or metadata changes.
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}