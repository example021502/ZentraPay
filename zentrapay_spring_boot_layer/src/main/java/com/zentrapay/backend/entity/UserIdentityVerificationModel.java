package com.zentrapay.backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

// Stores a user's submitted KYC identity details, document image references, and verification state.
@Entity
@Data
@Table(
        name = "user_identity_verifications",
        indexes = {
                // Speeds up loading a user's KYC submissions and checking verification status.
                @Index(
                        name = "idx_user_id_verifications_user_status",
                        columnList = "user_id, verification_status"
                ),
                // Speeds up lookups by identity type and country.
                @Index(
                        name = "idx_user_id_verifications_country_type",
                        columnList = "country_code, identity_type_key"
                )
        }
)
public class UserIdentityVerificationModel {

    // Primary identifier for the user identity verification record.
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    // User who owns this KYC/identity submission.
    @Column(name = "user_id", nullable = false, updatable = false)
    private UUID userId;

    // Country of issuance/verification (ISO 3166-1 alpha-2, e.g., NG, KE, GH).
    @Column(name = "country_code", nullable = false, length = 2)
    private String countryCode;

    // Identity type key matching supported_identity_types (e.g., BVN, NIN, PASSPORT).
    @Column(name = "identity_type_key", nullable = false, length = 40)
    private String identityTypeKey;

    // Encrypted identity/document number (encrypt before persisting; never log in plain text).
    @Column(name = "identity_number_encrypted", nullable = false, columnDefinition = "TEXT")
    private String identityNumberEncrypted;

    // Masked display value safe for UI/audit previews (e.g., "******4821").
    @Column(name = "masked_identity_number", length = 40)
    private String maskedIdentityNumber;

    // Storage path or URL to the front image of the identity document.
    @Column(name = "front_image_url", columnDefinition = "TEXT")
    private String frontImageUrl;

    // Storage path or URL to the back image of the identity document (when applicable).
    @Column(name = "back_image_url", columnDefinition = "TEXT")
    private String backImageUrl;

    // Optional selfie/liveness image URL if collected alongside document KYC.
    @Column(name = "selfie_image_url", columnDefinition = "TEXT")
    private String selfieImageUrl;

    // Optional document issue date.
    @Column(name = "issue_date")
    private LocalDate issueDate;

    // Optional document expiration date.
    @Column(name = "expiry_date")
    private LocalDate expiryDate;

    // Current verification lifecycle state (e.g., PENDING, VERIFIED, REJECTED, EXPIRED).
    @Column(name = "verification_status", nullable = false, length = 20)
    private String verificationStatus = "PENDING";

    // External provider/gateway reference or verification ID (e.g., Fincra/KYC check reference).
    @Column(name = "provider_reference", length = 120)
    private String providerReference;

    // Reason for rejection or manual review if verification fails.
    @Column(name = "rejection_reason", length = 500)
    private String rejectionReason;

    // Timestamp when verification succeeded.
    @Column(name = "verified_at")
    private LocalDateTime verifiedAt;

    // Timestamp when the submission was created.
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // Timestamp automatically updated when verification status or document details change.
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}