package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserProfileModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.UserProfileRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.UserRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.FileSystemResource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Tier-2 KYC document storage — POST/GET {@code /api/users/me/documents/{type}}.
 * <p>
 * Stored on local disk under {@code app.uploads.dir} (dev-appropriate;
 * swappable for S3/Cloudinary later without changing the controller's
 * shape, since it's already keyed by an opaque path string on
 * {@link UserProfileModel}, not a raw filesystem assumption elsewhere).
 * Every upload recomputes the caller's {@code kycTier} via
 * {@link UsersService#recomputeKycTier}.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DocumentsService {

    public static final Set<String> VALID_TYPES = Set.of("id-front", "id-back", "selfie");

    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;
    private final UsersService usersService;

    @Value("${app.uploads.dir}")
    private String uploadsDir;

    @Transactional
    public void upload(UUID userId, String type, MultipartFile file) {
        requireValidType(type);
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("No file was uploaded");
        }

        UserModel user = userRepository.getUserById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        UserProfileModel profile = userProfileRepository.getBtUserId(userId);
        if (profile == null) {
            profile = new UserProfileModel();
            profile.setUserId(userId);
        }

        try {
            Path dir = Path.of(uploadsDir, "documents");
            Files.createDirectories(dir);

            String extension = extensionOf(file.getOriginalFilename());
            String filename = userId + "_" + type + extension;
            Path target = dir.resolve(filename);
            file.transferTo(target);

            String relativePath = "documents/" + filename;
            applyPath(profile, type, relativePath);
        } catch (IOException e) {
            log.error("Failed to store {} document for user {}: {}", type, userId, e.getMessage());
            throw new UncheckedIOException("Could not save the uploaded document, please try again", e);
        }

        profile = userProfileRepository.save(profile);
        usersService.recomputeKycTier(user, profile);
    }

    /** Streams a previously-uploaded document back to its owner. */
    public FileSystemResource retrieve(UUID userId, String type) {
        requireValidType(type);
        UserProfileModel profile = userProfileRepository.getBtUserId(userId);
        String relativePath = profile == null ? null : pathFor(profile, type);
        if (relativePath == null || relativePath.isBlank()) {
            throw new ResourceNotFoundException("No " + type + " document has been uploaded yet");
        }
        Path resolved = Path.of(uploadsDir).resolve(relativePath);
        if (!Files.exists(resolved)) {
            throw new ResourceNotFoundException("Stored document is missing");
        }
        return new FileSystemResource(resolved);
    }

    private void requireValidType(String type) {
        if (type == null || !VALID_TYPES.contains(type.toLowerCase(Locale.ROOT))) {
            throw new IllegalArgumentException("Unknown document type: " + type + " (expected one of " + VALID_TYPES + ")");
        }
    }

    private void applyPath(UserProfileModel profile, String type, String relativePath) {
        switch (type.toLowerCase(Locale.ROOT)) {
            case "id-front" -> profile.setIdDocumentFrontPath(relativePath);
            case "id-back" -> profile.setIdDocumentBackPath(relativePath);
            case "selfie" -> profile.setSelfiePath(relativePath);
            default -> throw new IllegalArgumentException("Unknown document type: " + type);
        }
    }

    private String pathFor(UserProfileModel profile, String type) {
        return switch (type.toLowerCase(Locale.ROOT)) {
            case "id-front" -> profile.getIdDocumentFrontPath();
            case "id-back" -> profile.getIdDocumentBackPath();
            case "selfie" -> profile.getSelfiePath();
            default -> null;
        };
    }

    private String extensionOf(String originalFilename) {
        if (originalFilename == null) return "";
        int dot = originalFilename.lastIndexOf('.');
        // Comment: only keep a short, plausible image/pdf extension — never
        // trust the raw client filename beyond that into a path.
        if (dot < 0 || originalFilename.length() - dot > 6) return "";
        String ext = originalFilename.substring(dot).toLowerCase(Locale.ROOT);
        return ext.matches("\\.[a-z0-9]{1,5}") ? ext : "";
    }
}
