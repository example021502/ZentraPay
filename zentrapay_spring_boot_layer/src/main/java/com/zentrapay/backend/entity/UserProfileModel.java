package com.zentrapay.backend.entity;

import com.zentrapay.backend.service.common.Datatypes;
import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Data
@Table(name = "user_profiles")
public class UserProfileModel {
    // Unique identifier for the user profile.
    @Id
    @Column(name = "user_id", nullable = false, unique = true)
    private UUID userId;

    @Column(name = "date_of_birth")
    private LocalDate dateOfBirth;

    // ISO 3166-1 alpha-2 nationality code (essential for sanctions matching).
    @Column(name = "nationality_country_code", length = 3)
    private String nationalityCountryCode;

    // Identity Document details expanded for clarity.
    @Column(name = "identity_document_type", length = 30)
    private String identityDocumentType;

    @Column(name = "identity_document_number", length = 60)
    private String identityDocumentNumber;

    @Column(name = "identity_document_issuing_country_code")
    private String identityDocumentIssuingCountryCode;

    @Column(name = "identity_document_expiration_date")
    private LocalDate identityDocumentExpirationDate;

    // Residential address details expanded to full names.
    @Column(name = "address_1", length = 120)
    private String addressLine1;

    @Column(name = "address_2", length = 120)
    private String addressLine2;

    @Column(name = "city_name", length = 60)
    private String cityName;

    @Column(name = "state_or_region", length = 60)
    private String stateOrRegion;

    @Column(name = "postal_code", length = 20)
    private String postalCode;

    @Column(name = "occupation_title", length = 80)
    private String occupationTitle;

    // Comprehensive Compliance and Risk tracking fields.
    @Convert(converter = AmlStatusConverter.class)
    @Column(name = "anti_money_laundering_status", nullable = false, length = 20)
    private Datatypes.AntiMoneyStatuses antiMoneyLaunderingStatus = Datatypes.AntiMoneyStatuses.IN_REVIEW;

    @Column(name = "politically_exposed_person", nullable = false)
    private boolean isPoliticallyExposedPerson;

    @Column(name = "risk_score_level", length = 20)
    private String riskScoreLevel;

    @Column(name = "kyc_status", nullable = false, length = 20)
    private String KYCStatus = "pending";

    // LEGACY local-disk paths from before documents moved to the image host.
    // No longer written or read; kept only so the existing columns still map.
    @Column(name = "id_document_front_path", length = 255)
    private String idDocumentFrontPath;

    @Column(name = "id_document_back_path", length = 255)
    private String idDocumentBackPath;

    @Column(name = "selfie_path", length = 255)
    private String selfiePath;

    // Tier-2 document images live on the external image host; only the URL it
    // returned is saved here (see DocumentsService / ImageHostingService).
    // nullable until each is uploaded. All three plus the identity / address /
    // occupation fields above must be present before the profile is submitted
    // for review; a verification officer then grants tier 2
    // (see KycVerificationService).
    @Column(name = "id_document_front_image_url", length = 500)
    private String idDocumentFrontImageUrl;

    @Column(name = "id_document_back_image_url", length = 500)
    private String idDocumentBackImageUrl;

    @Column(name = "selfie_image_url", length = 500)
    private String selfieImageUrl;

    // KYC review trail: when the complete profile was submitted, and who
    // decided on it, when, and why (see KycVerificationService).
    @Column(name = "kyc_submitted_at")
    private LocalDateTime kycSubmittedAt;

    @Column(name = "kyc_reviewed_at")
    private LocalDateTime kycReviewedAt;

    @Column(name = "kyc_reviewed_by")
    private UUID kycReviewedBy;

    @Column(name = "kyc_review_note", length = 500)
    private String kycReviewNote;

    // System audit timestamps.
    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
