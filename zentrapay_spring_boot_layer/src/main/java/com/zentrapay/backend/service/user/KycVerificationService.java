package com.zentrapay.backend.service.user;

import com.zentrapay.backend.dto.kyc.KycReviewDTOs;
import com.zentrapay.backend.entity.NotificationModel;
import com.zentrapay.backend.entity.UserModel;
import com.zentrapay.backend.entity.UserProfileModel;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.repository.NotificationRepository;
import com.zentrapay.backend.repository.UserProfileRepository;
import com.zentrapay.backend.repository.UserRepository;
import com.zentrapay.backend.service.common.Datatypes;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

/**
 * The KYC review workflow.
 * <ol>
 *   <li>The user fills in the profile and uploads the three document images
 *       (front, back, selfie) - see {@code UsersService#upsertKycProfile} and
 *       {@link DocumentsService}. After each save {@link #checkSubmission} reads
 *       the profile back from the database and, once every required item is
 *       there, marks it {@code submitted}.</li>
 *   <li>A verification officer ({@code KYC_OFFICER}, or {@code ADMIN}) opens the
 *       queue, looks at the hosted images and either {@link #approve approves}
 *       - which is the ONLY thing that raises the user to tier 2 - or
 *       {@link #reject rejects} with a reason.</li>
 * </ol>
 * {@code kyc_status}: {@code pending} (incomplete) -> {@code submitted} (waiting
 * for an officer) -> {@code verified} | {@code rejected}.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class KycVerificationService {

    public static final String PENDING = "pending";
    public static final String SUBMITTED = "submitted";
    public static final String VERIFIED = "verified";
    public static final String REJECTED = "rejected";

    private static final Set<String> QUEUE_STATUSES = Set.of(SUBMITTED, VERIFIED, REJECTED, PENDING);

    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;
    private final NotificationRepository notificationRepository;

    // ====================================================================
    // User side: has everything required been provided?
    // ====================================================================

    /** What is still missing from the profile; empty means it can be reviewed. */
    public List<String> missingRequirements(UserProfileModel p) {
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
        if (blank(p.getIdentityDocumentType())) missing.add("ID document type");
        if (blank(p.getIdentityDocumentNumber())) missing.add("ID document number");
        if (blank(p.getIdDocumentFrontImageUrl())) missing.add("ID front image");
        if (blank(p.getIdDocumentBackImageUrl())) missing.add("ID back image");
        if (blank(p.getSelfieImageUrl())) missing.add("Selfie");
        return missing;
    }

    /**
     * Reads the user's profile back from the database and checks it: when
     * nothing required is missing, the profile is queued for an officer
     * ({@code submitted}); otherwise it stays {@code pending}. It never touches the tier.
     *
     * @param documentsChanged true when an image was just (re)uploaded. A profile
     *                         an officer already verified stays verified after a
     *                         plain field edit, but is sent back for review when a
     *                         document image itself was replaced.
     * @return the freshly read profile (null if the user has none yet)
     */
    @Transactional
    public UserProfileModel checkSubmission(UUID userId, boolean documentsChanged) {
        UserProfileModel profile = userProfileRepository.getBtUserId(userId);
        if (profile == null) {
            return null;
        }

        List<String> missing = missingRequirements(profile);
        String status = profile.getKYCStatus() == null ? PENDING : profile.getKYCStatus();

        if (missing.isEmpty()) {
            boolean waitingOrDone = SUBMITTED.equals(status)
                    || (VERIFIED.equals(status) && !documentsChanged);
            if (!waitingOrDone) {
                profile.setKYCStatus(SUBMITTED);
                profile.setKycSubmittedAt(LocalDateTime.now());
                profile.setKycReviewNote(null);
                profile = userProfileRepository.save(profile);
                log.info("KYC profile of user {} is complete and queued for review", userId);
            }
        } else if (SUBMITTED.equals(status)) {
            // Cannot normally happen (nothing is ever cleared), but never leave an
            // incomplete profile sitting in the officer's queue.
            profile.setKYCStatus(PENDING);
            profile = userProfileRepository.save(profile);
        }
        return profile;
    }

    // ====================================================================
    // Officer side
    // ====================================================================

    @Transactional(readOnly = true)
    public List<KycReviewDTOs.Summary> queue(Datatypes.UserType caller, String status, int limit, int offset) {
        requireOfficer(caller);
        String wanted = status == null || status.isBlank() ? SUBMITTED : status.toLowerCase(Locale.ROOT);
        if (!QUEUE_STATUSES.contains(wanted)) {
            throw new IllegalArgumentException("Unknown status: " + status);
        }
        int size = Math.min(Math.max(limit, 1), 100);
        int page = Math.max(offset, 0) / size;
        return userProfileRepository.findByReviewStatus(wanted, PageRequest.of(page, size)).stream()
                .map(p -> {
                    UserModel u = userRepository.getUserByUserId(p.getUserId()).orElse(null);
                    return new KycReviewDTOs.Summary(
                            p.getUserId(),
                            u == null ? "" : (u.getFirstName() + " " + u.getLastName()).trim(),
                            u == null ? "" : u.getEmail(),
                            u == null ? "" : u.getCountryCode(),
                            u == null ? 0 : u.getKycTier(),
                            p.getKYCStatus(),
                            p.getKycSubmittedAt());
                })
                .toList();
    }

    @Transactional(readOnly = true)
    public KycReviewDTOs.Submission submission(Datatypes.UserType caller, UUID userId) {
        requireOfficer(caller);
        return toSubmission(requireUser(userId), requireProfile(userId));
    }

    /**
     * The officer is satisfied: checks the profile is still complete, then marks
     * it verified and raises the user to tier 2.
     */
    @Transactional
    public KycReviewDTOs.Submission approve(Datatypes.UserType callerType, UUID officerId, UUID userId, String note) {
        requireOfficer(callerType);
        requireNotSelf(officerId, userId);
        UserModel user = requireUser(userId);
        UserProfileModel profile = requireProfile(userId);

        List<String> missing = missingRequirements(profile);
        if (!missing.isEmpty()) {
            throw new IllegalStateException("This profile is not complete yet: " + String.join(", ", missing));
        }

        profile.setKYCStatus(VERIFIED);
        profile.setKycReviewedAt(LocalDateTime.now());
        profile.setKycReviewedBy(officerId);
        profile.setKycReviewNote(trimmedOrNull(note));
        userProfileRepository.save(profile);

        user.setKycTier((short) 2);
        userRepository.save(user);

        notify(userId, "Identity verified",
                "Your documents were checked and approved. You can now send and receive money.");
        log.info("KYC of user {} approved by officer {} - tier 2 granted", userId, officerId);
        return toSubmission(user, profile);
    }

    /** The documents do not check out: the user is told why and can resubmit. */
    @Transactional
    public KycReviewDTOs.Submission reject(Datatypes.UserType callerType, UUID officerId, UUID userId, String reason) {
        requireOfficer(callerType);
        requireNotSelf(officerId, userId);
        String why = trimmedOrNull(reason);
        if (why == null) {
            throw new IllegalArgumentException("Please give a reason so the user knows what to fix");
        }
        UserModel user = requireUser(userId);
        UserProfileModel profile = requireProfile(userId);

        profile.setKYCStatus(REJECTED);
        profile.setKycReviewedAt(LocalDateTime.now());
        profile.setKycReviewedBy(officerId);
        profile.setKycReviewNote(why);
        userProfileRepository.save(profile);

        // A rejected review withdraws any tier-2 access earlier granted.
        user.setKycTier((short) 1);
        userRepository.save(user);

        notify(userId, "Verification needs attention",
                "We could not verify your documents: " + why + " Please update them and submit again.");
        log.info("KYC of user {} rejected by officer {}", userId, officerId);
        return toSubmission(user, profile);
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

    private UserModel requireUser(UUID userId) {
        return userRepository.getUserByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }

    private UserProfileModel requireProfile(UUID userId) {
        UserProfileModel profile = userProfileRepository.getBtUserId(userId);
        if (profile == null) {
            throw new ResourceNotFoundException("This user has not submitted a profile");
        }
        return profile;
    }

    private void notify(UUID userId, String title, String message) {
        NotificationModel n = new NotificationModel();
        n.setUserId(userId);
        n.setTitle(title);
        n.setMessage(message.length() > 500 ? message.substring(0, 497) + "..." : message);
        n.setType("SYSTEM");
        notificationRepository.save(n);
    }

    private KycReviewDTOs.Submission toSubmission(UserModel u, UserProfileModel p) {
        return new KycReviewDTOs.Submission(
                u.getUserId(),
                (u.getFirstName() + " " + u.getLastName()).trim(),
                u.getEmail(),
                u.getPhoneNumber(),
                u.getCountryCode(),
                u.getKycTier(),
                p.getKYCStatus(),
                p.getKycSubmittedAt(),
                p.getKycReviewedAt(),
                p.getKycReviewedBy(),
                p.getKycReviewNote(),
                p.getDateOfBirth(),
                p.getNationalityCountryCode(),
                p.getIdentityDocumentType(),
                p.getIdentityDocumentNumber(),
                p.getIdentityDocumentIssuingCountryCode(),
                p.getIdentityDocumentExpirationDate(),
                p.getAddressLine1(),
                p.getAddressLine2(),
                p.getCityName(),
                p.getStateOrRegion(),
                p.getPostalCode(),
                p.getOccupationTitle(),
                p.getIdDocumentFrontImageUrl(),
                p.getIdDocumentBackImageUrl(),
                p.getSelfieImageUrl(),
                missingRequirements(p));
    }

    private static boolean blank(String s) {
        return s == null || s.isBlank();
    }

    private static String trimmedOrNull(String s) {
        return s == null || s.isBlank() ? null : s.trim();
    }
}
