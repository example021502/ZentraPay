package com.zentrapay.backend.dto.ReviewOfficer;

/**
 * Request / response shapes of the verification officer's review API ({@code /api/kyc/review}).
 */
public record ApproveKycDocumentResponse(
        boolean success,
        String message
) {
}
