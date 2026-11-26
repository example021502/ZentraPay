package com.zentrapay.backend.dto.user;

import com.zentrapay.backend.service.common.Datatypes;
import jakarta.persistence.Column;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Response shape for {@code GET/PATCH /api/users/me} (API contract §1):
 * {@code {userId,firstName,lastName,email,phoneNumber,countryCode,zentag,userType,status,kycTier}}.
 */
public record UserProfileDTO(
        LocalDate dateOfBirth,
        String countryCode,
        String addressLine1,
        String addressLine2,
        String cityName,
        String stateOrRegion,
        String postalCode,
        String occupationTitle,
        Datatypes.AntiMoneyStatuses antiMoneyLaunderingStatus,
        boolean isPoliticallyExposedPerson,
        Datatypes.UserRiskScoreLevel riskScoreLevel,
        @CreationTimestamp
        LocalDateTime createdAt,
        @UpdateTimestamp
        LocalDateTime updatedAt
) {
}
