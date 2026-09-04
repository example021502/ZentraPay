package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto;

import jakarta.persistence.Column;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Response shape for {@code GET/PATCH /api/users/me} (API contract §1):
 * {@code {userId,firstName,lastName,email,phoneNumber,countryCode,zentag,userType,status,kycTier}}.
 */
public record UserProfileDTO(
    LocalDate dateOfBirth,
    // ISO 3166-1 alpha-2 nationality code (essential for sanctions matching).
    String nationalityCountryCode,
    // Identity Document details expanded for clarity.
    String identityDocumentType,
    String identityDocumentNumber,
    String identityDocumentIssuingCountryCode,
    LocalDate identityDocumentExpirationDate,
    // Residential address details expanded to full names.
    String addressLine1,
    String addressLine2,
    String cityName,
    String stateOrRegion,
    String postalCode,
    String occupationTitle,
    // Comprehensive Compliance and Risk tracking fields.
    String antiMoneyLaunderingStatus,
    boolean isPoliticallyExposedPerson,
    String riskScoreLevel,
    String KYCStatus,
    // Tier-2 document upload status — presence flags only, never the actual
    // storage path (that stays server-side; see DocumentsService).
    boolean hasIdDocumentFront,
    boolean hasIdDocumentBack,
    boolean hasSelfie,
    // System audit timestamps.
    @CreationTimestamp
    LocalDateTime createdAt,
    @UpdateTimestamp
    LocalDateTime updatedAt
) {
}
