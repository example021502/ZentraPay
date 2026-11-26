// Always add inline comments for code readability and maintenance
package com.zentrapay.backend.entity;

import com.zentrapay.backend.service.common.Datatypes;
import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

// Stores uploaded user KYC identity documents, selfie/liveness image URLs, and verification status.
@Entity
@Data
@Table(
        name = "user_kyc_documents",
        indexes = {
                // Speeds up loading all KYC documents submitted by a user.
                @Index(name = "idx_user_kyc_documents_user_id", columnList = "user_id"),
                // Speeds up querying KYC documents by user and verification status (e.g., PENDING or VERIFIED).
                @Index(name = "idx_user_kyc_documents_user_status", columnList = "user_id, verification_status")
        }
)
public class KYCDocumentModel {

    // Primary identifier for the KYC document record.
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    // ZentraPay user who owns/submitted this KYC document.
    @Column(name = "user_id", nullable = false, updatable = false)
    private UUID userId;

    // Optional link to a specific identity verification attempt/batch if you group checks.
    @Column(name = "verification_id")
    private UUID verificationId;

    // Type of KYC document uploaded (e.g., NATIONAL_ID, PASSPORT, DRIVERS_LICENSE, SELFIE).
    @Column(name = "document_type", nullable = false, length = 40)
    private Datatypes.KYCDocumentType documentType;

    // Optional document/ID number or reference associated with the upload.
    @Column(name = "document_number", length = 80)
    private String documentNumber;

    // Country code of the authority that issued the identity document.
    @Column(name = "document_issuing_country", length = 3)
    private String documentIssuingCountry;

    // Expiration date of the identity document, if applicable.
    @Column(name = "documentExpirationDate")
    private LocalDate documentExpirationDate;

    // Overall KYC verification status for the profile (e.g., pending, verified, rejected).
    @Column(name = "kyc_status", nullable = false, length = 20)
    private Datatypes.KYCDocumentVerificationStatus kycStatus = Datatypes.KYCDocumentVerificationStatus.PENDING;

    // URL to the uploaded front side of the identity document.
    @Column(name = "front_image_url", nullable = false, length = 512)
    private String frontImageUrl;

    // URL to the uploaded back side of the identity document (when applicable).
    @Column(name = "back_image_url", length = 512)
    private String backImageUrl;

    // URL to the uploaded selfie or liveness image paired with the KYC submission.
    @Column(name = "selfie_image_url", length = 512)
    private String selfieImageUrl;

    // Verification state of this uploaded KYC document (e.g., PENDING, VERIFIED, REJECTED).
    @Column(name = "verification_status", nullable = false, length = 30)
    private Datatypes.KYCDocumentVerificationStatus verificationStatus = Datatypes.KYCDocumentVerificationStatus.PENDING;

    // Explanation or rejection reason if KYC review marks this document as rejected.
    @Column(name = "rejection_reason", length = 500)
    private String rejectionReason;

    // Timestamp when a reviewer or automated check completed KYC review.
    @Column(name = "kyc_reviewed_at")
    private LocalDateTime kycReviewedAt;

    // Admin or operator user ID who reviewed the KYC submission.
    @Column(name = "kyc_reviewed_by")
    private UUID kycReviewedBy;

    // Reviewer notes or rejection reason from KYC evaluation.
    @Column(name = "kyc_review_note", length = 500)
    private String kycReviewNote;

    // Optimistic lock version to guard against concurrent KYC or compliance updates.
    @Version
    @Column(name = "version", nullable = false)
    private Long version;

    // Timestamp when the KYC document record was created.
    @CreationTimestamp
    @Column(name = "submitted_at", nullable = false, updatable = false)
    private LocalDateTime submittedAt;

    // Timestamp automatically updated whenever status, URLs, or review notes change.
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}