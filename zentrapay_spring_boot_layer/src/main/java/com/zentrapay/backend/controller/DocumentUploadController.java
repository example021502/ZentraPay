package com.zentrapay.backend.controller;

import com.zentrapay.backend.dto.common.ApiResponse;
import com.zentrapay.backend.repository.KYCDocumentRepository;
import com.zentrapay.backend.security.AuthenticatedUser;
import com.zentrapay.backend.security.CurrentUser;
import com.zentrapay.backend.service.user.KycDocumentsServices;
import lombok.RequiredArgsConstructor;

import java.util.Map;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;


@RestController
@RequestMapping("/api/users/me/documents")
@RequiredArgsConstructor
public class DocumentUploadController {

    private final KycDocumentsServices kycDocumentsServices;

    @PostMapping(value = "/{type}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<Void>> upload(
            @CurrentUser AuthenticatedUser user,
            @PathVariable String type,
            @RequestParam("file") MultipartFile file) {
        kycDocumentsServices.upload(user.getUserId(), type, file);
        return ResponseEntity.ok(ApiResponse.success("Document uploaded"));
    }

    /**
     * The hosted URL of a document the caller uploaded (the image itself lives on the image host).
     */
    @GetMapping("/{type}")
    public ResponseEntity<ApiResponse<Map<String, String>>> retrieve(
            @CurrentUser AuthenticatedUser user,
            @PathVariable String type) {
        String url = kycDocumentsServices.retrieveUrl(user.getUserId(), type);
        return ResponseEntity.ok(ApiResponse.success(Map.of("url", url), "Document retrieved"));
    }
}
