package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * The single canonical mapping of the "users" table. Every module that
 * needs a user (payments, search, transactions, ...) reads/writes this
 * entity — no module should declare its own parallel @Entity for "users".
 */
@Entity
@Data
@Table(name = "users")
public class UserModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "first_name", nullable = false, length = 60)
    private String firstName;

    @Column(name = "last_name", nullable = false, length = 60)
    private String lastName;

    @Column(name = "email", nullable = false, unique = true, length = 120)
    private String email;

    @Column(name = "phone_number", nullable = false, unique = true, length = 20)
    private String phoneNumber;

    @Column(name = "country_code", nullable = false, length = 2)
    private String countryCode;

    @Column(name = "password_hash", nullable = false, length = 120)
    private String passwordHash;

    @Column(name = "transaction_pin_hash", nullable = false, length = 120)
    private String transactionPinHash;

    @Column(name = "zentag", nullable = false, unique = true, length = 40)
    private String zentag;

    @Column(name = "user_type", nullable = false, length = 20)
    private String userType = "INDIVIDUAL"; // INDIVIDUAL, MERCHANT

    @Column(name = "status", nullable = false, length = 20)
    private String status = "ACTIVE"; // ACTIVE, SUSPENDED, PENDING_VERIFICATION, CLOSED

    @Column(name = "kyc_tier", nullable = false)
    private short kycTier = 0;


    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    public String getFullName() {
        return firstName + " " + lastName;
    }
}
