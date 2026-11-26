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

// Canonical mapping for multi-currency virtual accounts and user wallets in ZentraPay.
@Entity
@Data
@Table(
        name = "virtual_accounts",
        uniqueConstraints = {
                // Ensures one virtual account per user and ISO currency code (matches currency_code column name).
                @UniqueConstraint(
                        name = "uk_virtual_accounts_user_currency",
                        columnNames = {"user_id", "currency_code"}
                )
        },
        indexes = {
                // Speeds up loading all virtual accounts/wallets owned by a user.
                @Index(name = "idx_virtual_accounts_user_id", columnList = "user_id"),
                // Speeds up querying active accounts for a user.
                @Index(name = "idx_virtual_accounts_user_active", columnList = "user_id, is_active")
        }
)
public class AccountsModel {

    // Primary identifier for the virtual account / wallet record.
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, unique = true, updatable = false)
    private UUID id;

    // Owner user ID who holds this virtual account/wallet.
    @Column(name = "user_id", nullable = false, updatable = false)
    private UUID userId;

    // Unique merchant/system reference sent to or returned by the virtual account provider (e.g., Fincra).
    @Column(name = "zentag", nullable = false, unique = true, updatable = false, length = 128)
    private String zentag;

    // ISO 4217 currency code for this wallet/virtual account (e.g., NGN, KES, GHS).
    @Column(name = "currency_code", nullable = false, updatable = false, length = 3)
    private String currencyCode;

    // Provisioning or lifecycle state of the virtual account (e.g., ACTIVE, PENDING, INACTIVE, SUSPENDED).
    @Column(name = "status", nullable = false, length = 30)
    private String status;

    // Virtual account classification or rail type (e.g., INDIVIDUAL, DYNAMIC, STATIC, NUBAN).
    @Column(name = "account_type", nullable = false, length = 40)
    private Datatypes.AccountTypes accountType = Datatypes.AccountTypes.USER;

    // Assigned virtual bank account number used to receive inbound deposits.
    @Column(name = "phone_number", nullable = false, length = 40)
    private String phoneNumber;

    // User-facing or system label for this currency account/wallet.
    @Column(name = "label", nullable = false, length = 120)
    private String label;

    // Account holder email associated with the provisioned virtual account.
    @Column(name = "email", nullable = false, length = 120)
    private String email;

    // Current wallet/virtual-account balance; update through transactional ledger/service operations.
    @Column(name = "balance", nullable = false, precision = 19, scale = 4)
    private BigDecimal balance = BigDecimal.ZERO;

    // Indicates whether this virtual account is currently active and usable.
    @Column(name = "active", nullable = false)
    private Datatypes.AccountStatus active = Datatypes.AccountStatus.ACTIVE;

    // Indicates whether this is the user's default currency wallet/account.
    @Column(name = "is_default", nullable = false)
    private boolean isDefault = false;

    // Optimistic lock version to prevent lost updates during concurrent balance or status changes.
    @Version
    @Column(name = "version", nullable = false)
    private Long version;

    // Timestamp when the virtual account was created.
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // Timestamp automatically updated when account details, status, or balance change.
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}