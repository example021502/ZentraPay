package com.zentrapay.backend.service.user;

import com.zentrapay.backend.dto.ReviewOfficer.DetailedUserInformationDTO;
import com.zentrapay.backend.dto.ReviewOfficer.Requests.ApproveKycDocumentsRequest;
import com.zentrapay.backend.entity.KYCDocumentModel;
import com.zentrapay.backend.entity.NotificationModel;
import com.zentrapay.backend.entity.UserModel;
import com.zentrapay.backend.entity.UserProfileModel;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.repository.KYCDocumentRepository;
import com.zentrapay.backend.repository.NotificationRepository;
import com.zentrapay.backend.repository.UserRepository;
import com.zentrapay.backend.service.common.Datatypes;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.jspecify.annotations.NonNull;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;


@Slf4j
@Service
@RequiredArgsConstructor
public class KycDocumentsServices {


    private final KYCDocumentRepository kycDocuments;
    private final UserProfileServices userProfileServices;
    private final UsersService usersService;
    private final NotificationRepository notifications;
    private final UserRepository users;

    private final ImageHostingService imageHostingService;


    // updating the kyc documents table
    public void updateDocuments(
            UUID userId,
            Datatypes.KYCDocumentType documentType,
            String documentNumber,
            LocalDate documentExpirationDate,
            String issuingCountryCode
    ) {
        KYCDocumentModel d = getKycDocument(userId);
        if (documentType != null) {
            d.setDocumentType(documentType);
        }
        if (!documentNumber.isBlank()) {
            d.setDocumentNumber(documentNumber);
        }
        if (documentExpirationDate != null) {
            d.setDocumentExpirationDate(documentExpirationDate);
        }
        if (!issuingCountryCode.isBlank()) {
            d.setDocumentIssuingCountry(issuingCountryCode);
        }
    }

    public List<String> missingRequirements(UserProfileModel p, KYCDocumentModel d) {
        List<String> missing = new ArrayList<>();
        if (p == null) {
            missing.addAll(List.of("Date of birth", "Address", "City", "Occupation", "ID document type",
                    "ID document number", "ID front image", "ID back image", "Selfie"));
            return missing;
        }

        if (p.getDateOfBirth() == null) missing.add("Date of birth");
        if (blank(p.getAddressLine1())) missing.add("Address");
        if (blank(p.getCityName())) missing.add("City");
        if (blank(p.getOccupationTitle())) missing.add("Occupation");
        if (d.getDocumentType() == null) missing.add("ID document type");
        if (blank(d.getDocumentNumber())) missing.add("ID document number");
        if (blank(d.getFrontImageUrl())) missing.add("ID front image");
        if (blank(d.getBackImageUrl())) missing.add("ID back image");
        if (blank(d.getSelfieImageUrl())) missing.add("Selfie");
        return missing;
    }

    // GETTING THE USER KYC DOCUMENT INFORMATION
    @Transactional
    public KYCDocumentModel getKycDocument(UUID userId) {
        return kycDocuments.getKycDocumentByUserId(userId)
                .orElseGet(() -> {
                    KYCDocumentModel doc = new KYCDocumentModel();
                    doc.setUserId(userId);
                    return kycDocuments.save(doc);
                });
    }

    @Transactional
    public boolean checkSubmission(UUID userId) {
        KYCDocumentModel d = getKycDocument(userId);
        return !d.getKycStatus().equals(Datatypes.KYCDocumentVerificationStatus.PENDING);
    }

    // ====================================================================
    // Officer side
    // ====================================================================

    @Transactional(readOnly = true)
    public List<KYCDocumentModel> getQueue(Datatypes.UserType userType, Datatypes.KYCDocumentVerificationStatus status, int limit, int offset) throws IllegalAccessException {
        if (!List.of(Datatypes.KYCDocumentVerificationStatus.values()).contains(status)) {
            throw new IllegalArgumentException("Unknown status: " + status);
        }
        requireOfficer(userType);
        int size = Math.clamp(limit, 1, 100);
        int page = Math.max(offset, 0) / size;

        // Builds a Pageable from offset and limit, sorting oldest submissions first for fair review order.
        Sort sort = Sort.by(Sort.Direction.ASC, "createdAt").and(Sort.by(Sort.Direction.ASC, "id"));

        return kycDocuments.getQueuedDocuments(status, PageRequest.of(page, limit, sort));
    }

    @Transactional(readOnly = true)
    public DetailedUserInformationDTO getUserInformation(Datatypes.UserType type, UUID userId) {
        requireOfficer(type);
        return toDetailedUserInformation(usersService.getUser(userId), userProfileServices.getUserProfile(userId), getKycDocument(userId));
    }

    /**
     * The officer is satisfied: checks the profile is still complete, then marks
     * it verified and raises the user to tier 2.
     */
    @Transactional
    public void approve(Datatypes.UserType type, UUID officerId, UUID userId, ApproveKycDocumentsRequest body) {
        requireOfficer(type);
        requireNotSelf(officerId, userId);
        UserModel b_user = body.user();
        UserProfileModel b_profile = body.profile();
        KYCDocumentModel b_doc = body.document();

        UserModel t_user = usersService.getUser(userId);
        UserProfileModel t_profile = userProfileServices.getUserProfile(userId);
        KYCDocumentModel t_doc = getKycDocument(userId);

        if (!b_user.getId().equals(t_user.getId())) {
            throw new RuntimeException("Approved user information is different from system records");
        }

        if (!b_profile.getUserId().equals(t_profile.getUserId())) {
            throw new RuntimeException("Approved profile information is different from system records");
        }

        if (!b_doc.getUserId().equals(t_doc.getUserId())) {
            throw new RuntimeException("Approved documents is different from system records");
        }

        List<String> missing = missingRequirements(b_profile, b_doc);
        if (!missing.isEmpty()) {
            throw new IllegalStateException("This profile is not complete yet: " + String.join(", ", missing));
        }

        t_doc.setKycStatus(Datatypes.KYCDocumentVerificationStatus.VERIFIED);
        t_doc.setKycReviewedAt(LocalDateTime.now());
        t_doc.setKycReviewedBy(officerId);
        t_doc.setKycReviewNote(trimmedOrNull(body.note()));
        kycDocuments.save(t_doc);

        t_user.setKycTier((short) 2);
        users.save(t_user);

        notify(userId, "Identity verified",
                "Your documents were checked and approved. You can now send and receive money.");
        log.info("KYC of user {} approved by officer {} - tier 2 granted", userId, officerId);
    }


    /**
     * The documents do not check out: the user is told why and can resubmit.
     */
    @Transactional
    public void reject(Datatypes.UserType callerType, UUID officerId, UUID userId, String reason) {
        requireOfficer(callerType);
        requireNotSelf(officerId, userId);
        String why = trimmedOrNull(reason);
        if (why == null) {
            throw new IllegalArgumentException("Please give a reason so the user knows what to fix");
        }
        UserModel user = usersService.getUser(userId);
        UserProfileModel profile = userProfileServices.getUserProfile(userId);
        KYCDocumentModel doc = getKycDocument(userId);
        doc.setKycStatus(Datatypes.KYCDocumentVerificationStatus.REJECTED);
        doc.setKycReviewedAt(LocalDateTime.now());
        doc.setKycReviewedBy(officerId);
        doc.setKycReviewNote(why);
        kycDocuments.save(doc);

        // A rejected review withdraws any tier-2 access earlier granted.
        user.setKycTier((short) 1);
        users.save(user);

        notify(userId, "Verification needs attention",
                "We could not verify your documents: " + why + " Please update them and submit again.");
        log.info("KYC of user {} rejected by officer {}", userId, officerId);
    }

    // ====================================================================
    // helpers
    // ====================================================================

    private static void requireOfficer(Datatypes.UserType type) {
        if (type != Datatypes.UserType.KYC_OFFICER && type != Datatypes.UserType.ADMIN) {
            // Same answer as an unknown route, so the review API is not advertised to ordinary users.
            throw new ResourceNotFoundException("Resource not found");
        }
    }

    private static void requireNotSelf(UUID officerId, UUID userId) {
        if (officerId != null && officerId.equals(userId)) {
            throw new IllegalArgumentException("You cannot review your own documents");
        }
    }

    private void notify(UUID userId, String title, @NonNull String message) {
        NotificationModel n = new NotificationModel();
        n.setUserId(userId);
        n.setTitle(title);
        n.setMessage(message.length() > 500 ? message.substring(0, 497) + "..." : message);
        n.setType("SYSTEM");
        notifications.save(n);
    }

    private DetailedUserInformationDTO toDetailedUserInformation(UserModel u, UserProfileModel p, KYCDocumentModel d) {
        return new DetailedUserInformationDTO(
                u,
                p,
                d);
    }

    private static boolean blank(String s) {
        return s == null || s.isBlank();
    }

    private static String trimmedOrNull(String s) {
        return s == null || s.isBlank() ? null : s.trim();
    }

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

        UserModel user = usersService.getUser(userId);

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

        com.zentrapay.backend.entity.KYCDocumentModel doc = getKycDocument(userId);
        applyImageUrl(doc, documentType, hosted.url());

        if (checkSubmission(userId)) {
            throw new RuntimeException("The KYC documents are still pending.");
        }
        ;
    }

    /**
     * The hosted URL of a document the caller uploaded earlier.
     */
    public String retrieveUrl(UUID userId, String type) {
        String documentType = requireValidType(type);
        KYCDocumentModel document = getKycDocument(userId);
        String url = document == null ? null : urlFor(document, documentType);
        if (url == null || url.isBlank()) {
            throw new ResourceNotFoundException("No " + documentType + " document has been uploaded yet");
        }
        return url;
    }


    public static final Set<String> VALID_TYPES = Set.of("id-front", "id-back", "selfie");

    private static final Set<String> ALLOWED_CONTENT_TYPES = Set.of(
            "image/jpeg", "image/jpg", "image/png", "image/webp", "image/heic", "image/heif", "application/pdf");


    private String requireValidType(String type) {
        String normalised = type == null ? "" : type.toLowerCase(Locale.ROOT);
        if (!VALID_TYPES.contains(normalised)) {
            throw new IllegalArgumentException("Unknown document type: " + type + " (expected one of " + VALID_TYPES + ")");
        }
        return normalised;
    }

    private void applyImageUrl(KYCDocumentModel d, String type, String imageUrl) {
        switch (type) {
            case "id-front" -> d.setFrontImageUrl(imageUrl);
            case "id-back" -> d.setBackImageUrl(imageUrl);
            case "selfie" -> d.setSelfieImageUrl(imageUrl);
            default -> throw new IllegalArgumentException("Unknown document type: " + type);
        }
    }

    private String urlFor(KYCDocumentModel document, String type) {
        return switch (type) {
            case "id-front" -> document.getFrontImageUrl();
            case "id-back" -> document.getBackImageUrl();
            case "selfie" -> document.getSelfieImageUrl();
            default -> null;
        };
    }
}
