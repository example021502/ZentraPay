package com.zentrapay.backend.dto.ReviewOfficer.Requests;

import com.zentrapay.backend.entity.KYCDocumentModel;
import com.zentrapay.backend.entity.UserModel;
import com.zentrapay.backend.entity.UserProfileModel;


/**
 * Request / response shapes of the verification officer's review API ({@code /api/kyc/review}).
 */
public record ApproveKycDocumentsRequest(
        UserModel user,
        UserProfileModel profile,
        KYCDocumentModel document,
        String note
) {
}
