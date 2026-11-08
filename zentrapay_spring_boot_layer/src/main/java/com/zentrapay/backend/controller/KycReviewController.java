package com.zentrapay.backend.controller;

import com.zentrapay.backend.dto.common.ApiResponse;
import com.zentrapay.backend.dto.kyc.KycReviewDTOs;
import com.zentrapay.backend.security.AuthenticatedUser;
import com.zentrapay.backend.security.CurrentUser;
import com.zentrapay.backend.service.user.KycVerificationService;
import lombok.RequiredArgsConstructor;
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

    private final KycVerificationService kycVerificationService;

    /** The work queue; {@code status} defaults to {@code submitted} (waiting for review). */
    @GetMapping
    public ResponseEntity<ApiResponse<List<KycReviewDTOs.Summary>>> queue(
            @CurrentUser AuthenticatedUser officer,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "25") int limit,
            @RequestParam(defaultValue = "0") int offset) {
        return ResponseEntity.ok(ApiResponse.success(
                kycVerificationService.queue(officer.getUserType(), status, limit, offset), "KYC queue"));
    }

    /** One user's declared details plus the three hosted document images. */
    @GetMapping("/{userId}")
    public ResponseEntity<ApiResponse<KycReviewDTOs.Submission>> submission(
            @CurrentUser AuthenticatedUser officer, @PathVariable UUID userId) {
        return ResponseEntity.ok(ApiResponse.success(
                kycVerificationService.submission(officer.getUserType(), userId), "KYC submission"));
    }

    @PostMapping("/{userId}/approve")
    public ResponseEntity<ApiResponse<KycReviewDTOs.Submission>> approve(
            @CurrentUser AuthenticatedUser officer, @PathVariable UUID userId,
            @RequestBody(required = false) KycReviewDTOs.Decision body) {
        return ResponseEntity.ok(ApiResponse.success(
                kycVerificationService.approve(officer.getUserType(), officer.getUserId(), userId,
                        body == null ? null : body.note()),
                "User verified"));
    }

    @PostMapping("/{userId}/reject")
    public ResponseEntity<ApiResponse<KycReviewDTOs.Submission>> reject(
            @CurrentUser AuthenticatedUser officer, @PathVariable UUID userId,
            @RequestBody KycReviewDTOs.Decision body) {
        return ResponseEntity.ok(ApiResponse.success(
                kycVerificationService.reject(officer.getUserType(), officer.getUserId(), userId,
                        body == null ? null : body.note()),
                "Verification rejected"));
    }
}
