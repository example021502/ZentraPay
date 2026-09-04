package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.service.DocumentsService;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.AuthenticatedUser;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.FileSystemResource;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

/**
 * Tier-2 KYC document uploads — POST/GET {@code /api/users/me/documents/{type}}.
 * {@code type} is one of {@code id-front|id-back|selfie}. Every upload
 * recomputes the caller's {@code kycTier} (see {@link DocumentsService}).
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

    @GetMapping("/{type}")
    public ResponseEntity<FileSystemResource> retrieve(
            @CurrentUser AuthenticatedUser user,
            @PathVariable String type) {
        FileSystemResource resource = documentsService.retrieve(user.getUserId(), type);
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_OCTET_STREAM)
                .body(resource);
    }
}
