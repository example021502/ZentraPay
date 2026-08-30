package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

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
    @Column(name = "anti_money_laundering_status", nullable = false, length = 20)
    private String antiMoneyLaunderingStatus = "clear";

    @Column(name = "politically_exposed_person", nullable = false)
    private boolean isPoliticallyExposedPerson;

    @Column(name = "risk_score_level", length = 20)
    private String riskScoreLevel;

    @Column(name = "kyc_status", nullable = false, length = 20)
    private String KYCStatus = "pending";

    // System audit timestamps.
    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
