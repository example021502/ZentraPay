// Always add inline comments for code readability and maintenance
package com.zentrapay.backend.entity;

import com.zentrapay.backend.service.common.Datatypes;
import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

// Canonical mapping of the "users" table; every module referencing a user should use this entity.
@Entity
@Data
@Table(
        name = "users",
        indexes = {
                // Speeds up filtering/auditing users by account lifecycle status.
                @Index(name = "idx_users_status", columnList = "status"),
                // Speeds up corridor/regional queries by country and user status.
                @Index(name = "idx_users_country_status", columnList = "country_code, status")
        }
)
public class UserModel {

    // Primary identifier for the ZentraPay user.
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, unique = true, updatable = false)
    private UUID id;

    // User's given/first name.
    @Column(name = "first_name", nullable = false, length = 60)
    private String firstName;

    // User's family/last name.
    @Column(name = "last_name", nullable = false, length = 60)
    private String lastName;

    // Unique email address used for login, notifications, and account identification.
    @Column(name = "email", nullable = false, unique = true, length = 120)
    private String email;

    // Unique phone number in international/E.164-style format.
    @Column(name = "phone_number", nullable = false, unique = true, length = 20)
    private String phoneNumber;

    // Home/registered country code for the user (e.g., NG, KE, GH or alpha-3 per schema standard).
    @Column(name = "country_code", nullable = false, length = 3)
    private String countryCode;

    // Cryptographically hashed login password (never store raw passwords).
    @Column(name = "password_hash", nullable = false, length = 120)
    private String passwordHash;

    // Cryptographically hashed PIN used to authorize transfers, withdrawals, and bill payments.
    @Column(name = "transaction_pin_hash", nullable = false, length = 120)
    private String transactionPinHash;

    // Role/category of user account (e.g., APP_USER).
    @Enumerated(EnumType.STRING)
    @Column(name = "user_type", nullable = false, length = 20)
    private Datatypes.UserType userType = Datatypes.UserType.APP_USER;

    // Current account lifecycle status (e.g., ACTIVE, SUSPENDED, PENDING_VERIFICATION, CLOSED).
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private Datatypes.UserStatus status = Datatypes.UserStatus.ACTIVE;

    // Current verified KYC tier (e.g., 1, 2, 3) used for fast limit and feature checks.
    @Column(name = "kyc_tier", nullable = false)
    private short kycTier = 1;

    // Optimistic lock version to guard against concurrent status or KYC tier updates.
    @Version
    @Column(name = "version", nullable = false)
    private Long version;

    // Timestamp when the user account was created.
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // Timestamp automatically updated whenever user attributes or status change.
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}