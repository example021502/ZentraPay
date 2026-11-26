package com.zentrapay.backend.controller;

import com.zentrapay.backend.dto.ReviewOfficer.ApproveKycDocumentResponse;
import com.zentrapay.backend.dto.ReviewOfficer.DetailedUserInformationDTO;
import com.zentrapay.backend.dto.ReviewOfficer.Requests.ApproveKycDocumentsRequest;
import com.zentrapay.backend.dto.ReviewOfficer.Requests.RejectKycDocumentsRequest;
import com.zentrapay.backend.dto.common.ApiResponse;
import com.zentrapay.backend.entity.KYCDocumentModel;
import com.zentrapay.backend.security.AuthenticatedUser;
import com.zentrapay.backend.security.CurrentUser;
import com.zentrapay.backend.service.common.Datatypes;
import com.zentrapay.backend.service.user.KycDocumentsServices;
import lombok.RequiredArgsConstructor;
import org.jspecify.annotations.NonNull;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * The verification officer's API. Only {@code KYC_OFFICER} / {@code ADMIN}
 * accounts get an answer (anyone else sees "not found"). Approving a user here
 * is the only way a user reaches tier 2.
 */
@RestController
@RequestMapping("/api/kyc/review")
@RequiredArgsConstructor
public class KycReviewController {

    private final KycDocumentsServices kycDocumentsServices;

    /**
     * The work queue; {@code status} defaults to {@code submitted} (waiting for review).
     */
    @GetMapping("/queuedDocuments")
    public ResponseEntity<ApiResponse<List<KYCDocumentModel>>> queue(
            @CurrentUser @NonNull AuthenticatedUser user,
            @RequestParam(required = false) Datatypes.KYCDocumentVerificationStatus status,
            @RequestParam(defaultValue = "25") int limit,
            @RequestParam(defaultValue = "0") int offset) throws IllegalAccessException {
        return ResponseEntity.ok(ApiResponse.success(
                kycDocumentsServices.getQueue(user.getUserType(), status, limit, offset), "Documents retrieved."));
    }

    /**
     * One user's declared details plus the three hosted document images.
     * getting user information, user profile information and identity information
     */
    @GetMapping("/{userId}")
    public ResponseEntity<ApiResponse<DetailedUserInformationDTO>> getUserInformation(
            @CurrentUser AuthenticatedUser officer, @PathVariable UUID userId) {
        return ResponseEntity.ok(ApiResponse.success(
                kycDocumentsServices.getUserInformation(officer.getUserType(), userId), "KYC submission"));
    }

    //    KYC OFFICER APPROVING THE USER'S KYC DOCUMENTS AS VALID
    @PostMapping("/{userId}/approve")
    public ResponseEntity<ApiResponse<String>> approve(
            @CurrentUser AuthenticatedUser officer, @PathVariable UUID userId,
            @RequestBody(required = false) ApproveKycDocumentsRequest body) {
        kycDocumentsServices.approve(officer.getUserType(), officer.getUserId(), userId, body);
        return ResponseEntity.ok(ApiResponse.success("User verified"));
    }

    @PostMapping("/{userId}/reject")
    public ResponseEntity<ApiResponse<String>> reject(
            @CurrentUser AuthenticatedUser officer, @PathVariable UUID userId,
            @RequestBody RejectKycDocumentsRequest body) {
        kycDocumentsServices.reject(officer.getUserType(), officer.getUserId(), userId,
                body == null ? null : body.note());
        return ResponseEntity.ok(ApiResponse.success("Verification rejected"));
    }
}
