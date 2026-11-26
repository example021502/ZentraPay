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

// Stores extended user profile attributes, residential address, occupation, and KYC/AML compliance state (1:1 with users).
@Entity
@Data
@Table(
        name = "user_profiles",
        indexes = {
                // Speeds up querying profiles awaiting or completed in KYC review workflows.
                @Index(name = "idx_user_profiles_kyc_status", columnList = "kyc_status"),
                // Speeds up AML/sanctions screening queues and compliance audits.
                @Index(name = "idx_user_profiles_aml_status", columnList = "anti_money_laundering_status")
        }
)
public class UserProfileModel {

    // Primary key referencing users.id (1:1 profile per user).
    @Id
    @Column(name = "user_id", nullable = false, updatable = false)
    private UUID userId;

    // User's date of birth for age and KYC verification checks.
    @Column(name = "date_of_birth")
    private LocalDate dateOfBirth;

    // Country code representing the user's nationality for sanctions and compliance screening.
    @Column(name = "country_code", length = 3)
    private String countryCode;

    // Primary street or residential address line.
    @Column(name = "address_1", length = 120)
    private String addressLine1;

    // Secondary address line (apartment, suite, landmark, etc.).
    @Column(name = "address_2", length = 120)
    private String addressLine2;

    // City or town of residence.
    @Column(name = "city_name", length = 60)
    private String cityName;

    // State, county, or administrative region.
    @Column(name = "state_or_region", length = 60)
    private String stateOrRegion;

    // Postal or ZIP code, when applicable.
    @Column(name = "postal_code", length = 20)
    private String postalCode;

    // User's occupation or role title for compliance/risk profiling.
    @Column(name = "occupation_title", length = 80)
    private String occupationTitle;

    // Anti-money laundering screening status for the user.
    @Convert(converter = AmlStatusConverter.class)
    @Column(name = "anti_money_laundering_status", nullable = false, length = 20)
    private Datatypes.AntiMoneyStatuses antiMoneyLaunderingStatus = Datatypes.AntiMoneyStatuses.IN_REVIEW;

    // Indicates whether the user is flagged as a Politically Exposed Person (PEP).
    @Column(name = "politically_exposed_person", nullable = false)
    private boolean isPoliticallyExposedPerson;

    // Assessed risk tier/level (e.g., LOW, MEDIUM, HIGH).
    @Column(name = "risk_score_level", length = 20)
    private Datatypes.UserRiskScoreLevel riskScoreLevel = Datatypes.UserRiskScoreLevel.LOW;

    // Timestamp when the profile record was created.
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // Timestamp automatically updated when profile or compliance fields change.
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}