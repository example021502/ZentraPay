package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto;

import java.time.LocalDate;

/**
 * {@code PUT /api/users/me/profile} request body — only the fields a user
 * may set themselves. Deliberately excludes the compliance-computed fields
 * on {@link UserProfileDTO} ({@code antiMoneyLaunderingStatus},
 * {@code isPoliticallyExposedPerson}, {@code riskScoreLevel},
 * {@code KYCStatus}) — those are back-office/system-controlled, never
 * client-writable. Every field is optional; null means "leave unchanged",
 * so the KYC form can submit one section at a time.
 */
public record UserProfileUpdateDTO(
        LocalDate dateOfBirth,
        String nationalityCountryCode,
        String identityDocumentType,
        String identityDocumentNumber,
        String identityDocumentIssuingCountryCode,
        LocalDate identityDocumentExpirationDate,
        String addressLine1,
        String addressLine2,
        String cityName,
        String stateOrRegion,
        String postalCode,
        String occupationTitle
) {
}
