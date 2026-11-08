package com.zentrapay.backend.dto.kyc;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/** Request / response shapes of the verification officer's review API ({@code /api/kyc/review}). */
public final class KycReviewDTOs {

    private KycReviewDTOs() {
    }

    /** One row of the officer's work queue. */
    public record Summary(
            UUID userId,
            String fullName,
            String email,
            String countryCode,
            short kycTier,
            String kycStatus,
            LocalDateTime submittedAt
    ) {
    }

    /** Everything an officer needs to decide: the declared details and the three hosted images. */
    public record Submission(
            UUID userId,
            String fullName,
            String email,
            String phoneNumber,
            String countryCode,
            short kycTier,
            String kycStatus,
            LocalDateTime submittedAt,
            LocalDateTime reviewedAt,
            UUID reviewedBy,
            String reviewNote,
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
            String occupationTitle,
            String idDocumentFrontUrl,
            String idDocumentBackUrl,
            String selfieUrl,
            List<String> missingRequirements
    ) {
    }

    /** Body of approve / reject. {@code note} is optional on approve and required on reject. */
    public record Decision(String note) {
    }
}
