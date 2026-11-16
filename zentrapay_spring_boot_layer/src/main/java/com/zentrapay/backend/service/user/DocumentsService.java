package com.zentrapay.backend.service.user;

import com.zentrapay.backend.entity.UserModel;
import com.zentrapay.backend.entity.UserProfileModel;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.repository.UserProfileRepository;
import com.zentrapay.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

/**
 * KYC document images - POST/GET {@code /api/users/me/documents/{type}}.
 * <p>
 * The image is NOT kept in our database or on our disk: it is posted to the
 * external image host (see {@link ImageHostingService}, under the submitted
 * file name with the document type appended) and the URL the host returns is
 * what gets saved on the user's profile. After the save the profile is read back
 * and checked for completeness, which queues it for a verification officer
 * ({@link KycVerificationService}). Uploading never raises the tier - only the
 * officer's approval does.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DocumentsService {

    public static final Set<String> VALID_TYPES = Set.of("id-front", "id-back", "selfie");

    private static final Set<String> ALLOWED_CONTENT_TYPES = Set.of(
            "image/jpeg", "image/jpg", "image/png", "image/webp", "image/heic", "image/heif", "application/pdf");

    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;
    private final UsersService usersService;
    private final ImageHostingService imageHostingService;
    private final KycVerificationService kycVerificationService;

    @Transactional
    public void upload(UUID userId, String type, MultipartFile file) {
        log.info("Uploading KYC document {} for user {}", type, userId);
        String documentType = requireValidType(type);
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("No file was uploaded");
        }
        String contentType = file.getContentType() == null ? "" : file.getContentType().toLowerCase(Locale.ROOT);
        if (!ALLOWED_CONTENT_TYPES.contains(contentType)) {
            throw new IllegalArgumentException("Please upload a photo (JPG, PNG, WEBP) or a PDF");
        }

        UserModel user = userRepository.getUserByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        byte[] bytes;
        try {
            bytes = file.getBytes();
        } catch (IOException e) {
            log.error("Failed to read uploaded {} document for user {}: {}", documentType, userId, e.getMessage());
            throw new UncheckedIOException("Could not read the uploaded document, please try again", e);
        }

        // Host first: if it refuses the image nothing is saved.
        ImageHostingService.HostedImage hosted =
                imageHostingService.upload(file.getOriginalFilename(), documentType, bytes);
        if (hosted == null) {
            throw new IllegalStateException("File could not be uploaded, please try again later");
        }

        UserProfileModel profile = userProfileRepository.getByUserId(userId);
        if (profile == null) {
            profile = new UserProfileModel();
            profile.setUserId(userId);
        }
        applyImageUrl(profile, documentType, hosted.url());
        profile = userProfileRepository.save(profile);

        usersService.recomputeKycTier(user, profile);
        // Read the profile back and see whether all required documents are in.
        kycVerificationService.checkSubmission(userId, true);
    }

    /**
     * The hosted URL of a document the caller uploaded earlier.
     */
    public String retrieveUrl(UUID userId, String type) {
        String documentType = requireValidType(type);
        UserProfileModel profile = userProfileRepository.getByUserId(userId);
        String url = profile == null ? null : urlFor(profile, documentType);
        if (url == null || url.isBlank()) {
            throw new ResourceNotFoundException("No " + documentType + " document has been uploaded yet");
        }
        return url;
    }

    private String requireValidType(String type) {
        String normalised = type == null ? "" : type.toLowerCase(Locale.ROOT);
        if (!VALID_TYPES.contains(normalised)) {
            throw new IllegalArgumentException("Unknown document type: " + type + " (expected one of " + VALID_TYPES + ")");
        }
        return normalised;
    }

    private void applyImageUrl(UserProfileModel profile, String type, String imageUrl) {
        switch (type) {
            case "id-front" -> profile.setIdDocumentFrontImageUrl(imageUrl);
            case "id-back" -> profile.setIdDocumentBackImageUrl(imageUrl);
            case "selfie" -> profile.setSelfieImageUrl(imageUrl);
            default -> throw new IllegalArgumentException("Unknown document type: " + type);
        }
    }

    private String urlFor(UserProfileModel profile, String type) {
        return switch (type) {
            case "id-front" -> profile.getIdDocumentFrontImageUrl();
            case "id-back" -> profile.getIdDocumentBackImageUrl();
            case "selfie" -> profile.getSelfieImageUrl();
            default -> null;
        };
    }
}
