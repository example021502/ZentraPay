package com.zentrapay.backend.controller;

import com.zentrapay.backend.dto.common.ApiResponse;
import com.zentrapay.backend.service.user.DocumentsService;
import com.zentrapay.backend.security.AuthenticatedUser;
import com.zentrapay.backend.security.CurrentUser;
import lombok.RequiredArgsConstructor;
import java.util.Map;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

/**
 * KYC document uploads — POST/GET {@code /api/users/me/documents/{type}}.
 * {@code type} is one of {@code id-front|id-back|selfie}. An upload posts the
 * image to the image host and saves the returned URL; it submits the profile
 * for review but never raises the tier (a verification officer does, see
 * {@link DocumentsService} and {@code KycReviewController}).
 */
@RestController
@RequestMapping("/api/users/me/documents")
@RequiredArgsConstructor
public class DocumentUploadController {

    private final DocumentsService documentsService;

    @PostMapping(value = "/{type}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<Void>> upload(
            @CurrentUser AuthenticatedUser user,
            @PathVariable String type,
            @RequestParam("file") MultipartFile file) {
        documentsService.upload(user.getUserId(), type, file);
        return ResponseEntity.ok(ApiResponse.success(null, "Document uploaded"));
    }

    /** The hosted URL of a document the caller uploaded (the image itself lives on the image host). */
    @GetMapping("/{type}")
    public ResponseEntity<ApiResponse<Map<String, String>>> retrieve(
            @CurrentUser AuthenticatedUser user,
            @PathVariable String type) {
        String url = documentsService.retrieveUrl(user.getUserId(), type);
        return ResponseEntity.ok(ApiResponse.success(Map.of("url", url), "Document retrieved"));
    }
}
