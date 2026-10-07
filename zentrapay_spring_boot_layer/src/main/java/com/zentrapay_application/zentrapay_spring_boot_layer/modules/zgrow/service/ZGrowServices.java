package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.ChallengesModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.ChallengesProgressModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.ChallengesTargetModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.DeclinedChallengesModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserChallengesModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.ChallengesProgressRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.ChallengesRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.ChallengesTargetRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.DeclinedChallengesRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.RewardsRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.TutorialsRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.UserChallengesRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.Datatypes;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ResourceNotFoundException;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

/**
 * ZGrow — gamification content and savings challenges: rewards, tutorials,
 * the challenge catalog, and a user's own enrollments. Backed by the
 * rewards/tutorials tables plus the challenges, user_challenges,
 * challenges_targets and challenges_progress tables.
 */
@Service
@RequiredArgsConstructor
public class ZGrowServices {

    private final RewardsRepository rewardsRepository;
    private final TutorialsRepository tutorialsRepository;
    private final ChallengesRepository challengesRepository;
    private final UserChallengesRepository userChallengesRepository;
    private final ChallengesTargetRepository challengesTargetRepository;
    private final ChallengesProgressRepository challengesProgressRepository;
    private final DeclinedChallengesRepository declinedChallengesRepository;

    @Transactional(readOnly = true)
    public List<RewardsDTO> listRewards() {
        return rewardsRepository.findAll().stream().map(
                r-> new RewardsDTO(
                        r.getRewardId(),
                        r.getRewardType(),
                        r.getTitle(),
                        r.getDescription(),
                        r.getWorth(),
                        r.getCurrencyCode(),
                        r.getIsActive(),
                        r.getCreatedAt(),
                        r.getUpdatedAt()
                                )
        ).toList();
    }
    @Transactional(readOnly = true)
    public List<TutorialsDTO> listTutorials() {
        return tutorialsRepository.findAll().stream().map(
                r-> new TutorialsDTO(
                        r.getId(),
                        r.getTitle(),
                        r.getType(),
                        r.getDescription(),
                        r.getVideoUrl(),
                        r.getThumbnailUrl(),
                        r.getDurationSeconds(),
                        r.getIsActive(),
                        r.getCreatedAt(),
                        r.getUpdatedAt()
                )
                        ).toList();
    }

    // ========================================================================
    // CHALLENGES — CATALOG
    // ========================================================================

    /**
     * All challenges currently open for enrollment, with their target tiers
     * attached. Targets come from the target repository (ordered by tier)
     * rather than the LAZY {@code targets} collection, so this is safe to call
     * outside a transaction.
     */
    @Transactional(readOnly = true)
    public List<ChallengesResponseDTO> listActiveChallenges() {
        return challengesRepository.findByIsActiveTrue().stream()
                .map(this::toChallengeWithTargets)
                .toList();
    }

    /** Active challenges filtered to one category, for the ZGrow category tabs. */
    @Transactional(readOnly = true)
    public List<ChallengesResponseDTO> listActiveChallengesByCategory(Datatypes.ChallengeCategory category) {
        return challengesRepository.findByIsActiveTrueAndCategory(category).stream()
                .map(this::toChallengeWithTargets)
                .toList();
    }

    @Transactional(readOnly = true)
    public ChallengesResponseDTO getChallenge(UUID challengeId) {
        ChallengesModel challenge = challengesRepository.findById(challengeId)
                .orElseThrow(() -> new ResourceNotFoundException("Challenge not found"));
        return toChallengeWithTargets(challenge);
    }

    /** Challenge ids this user has declined — used to filter the catalog. */
    @Transactional(readOnly = true)
    public List<UUID> listDeclinedChallengeIds(UUID userId) {
        return declinedChallengesRepository.findByUserId(userId).stream()
                .map(DeclinedChallengesModel::getChallengeId)
                .toList();
    }

    // ========================================================================
    // CHALLENGES — USER ENROLLMENT
    // ========================================================================

    /**
     * Enroll the user in a challenge. The target amount is snapshotted from the
     * lowest tier at join time and {@code endsAt} is derived from the
     * challenge's {@code durationDays}, matching the columns the
     * {@code user_challenges} table defines.
     */
    @Transactional
    public UserChallengesResponseDTO enroll(UUID userId, UUID challengeId) {
        ChallengesModel challenge = challengesRepository.findById(challengeId)
                .orElseThrow(() -> new ResourceNotFoundException("Challenge not found"));

        if (!Boolean.TRUE.equals(challenge.getIsActive())) {
            throw new IllegalStateException("This challenge is no longer active");
        }

        // user_challenges has a UNIQUE (user_id, challenge_id) constraint, so a
        // second insert would fail at the DB level — reject it up front instead.
        userChallengesRepository.findByUserIdAndChallengeId(userId, challengeId)
                .ifPresent(existing -> {
                    throw new IllegalStateException("You have already joined this challenge");
                });

        List<ChallengesTargetModel> targets =
                challengesTargetRepository.findByChallengeIdOrderByTierLevelAsc(challengeId);
        if (targets.isEmpty()) {
            throw new IllegalStateException("This challenge has no targets configured");
        }
        BigDecimal targetAmount = targets.stream()
                .map(ChallengesTargetModel::getTargetAmount)
                .min(Comparator.naturalOrder())
                .orElseThrow(() -> new ResourceNotFoundException("Challenge has no target amount"));

        LocalDateTime now = LocalDateTime.now();
        UserChallengesModel enrollment = UserChallengesModel.builder()
                .userId(userId)
                .challenge(challenge)
                .status(Datatypes.ChallengeStatus.IN_PROGRESS)
                .currentAmount(BigDecimal.ZERO)
                .targetAmount(targetAmount)
                .startedAt(now)
                .endsAt(now.plusDays(challenge.getDurationDays()))
                .build();

        UserChallengesModel saved = userChallengesRepository.save(enrollment);

        // Rejoining after a previous decline re-opens the challenge for this user.
        declinedChallengesRepository.findByUserIdAndChallengeId(userId, challengeId)
                .ifPresent(declinedChallengesRepository::delete);

        return toUserChallengeWithLogs(saved);
    }

    /** Every challenge the user has enrolled in. */
    @Transactional(readOnly = true)
    public List<UserChallengesResponseDTO> listMyChallenges(UUID userId) {
        return userChallengesRepository.findByUserId(userId).stream()
                .map(this::toUserChallengeWithLogs)
                .toList();
    }

    @Transactional(readOnly = true)
    public UserChallengesResponseDTO getMyChallenge(UUID userId, UUID userChallengeId) {
        return toUserChallengeWithLogs(requireOwnedEnrollment(userId, userChallengeId));
    }

    /**
     * Record a contribution against an enrollment. The running total is
     * recomputed as currentAmount + contribution, written to the progress
     * ledger, and the enrollment flips to COMPLETED once the target is reached.
     */
    @Transactional
    public UserChallengesResponseDTO logProgress(UUID userId, UUID userChallengeId, BigDecimal amount,
                                                 UUID transactionReference, String notes) {
        UserChallengesModel enrollment = requireOwnedEnrollment(userId, userChallengeId);

        if (enrollment.getStatus() != Datatypes.ChallengeStatus.IN_PROGRESS) {
            throw new IllegalStateException("This challenge is no longer in progress");
        }
        if (LocalDateTime.now().isAfter(enrollment.getEndsAt())) {
            throw new IllegalStateException("This challenge has already ended");
        }

        BigDecimal current = enrollment.getCurrentAmount() == null
                ? BigDecimal.ZERO : enrollment.getCurrentAmount();
        BigDecimal newTotal = current.add(amount);

        ChallengesProgressModel entry = ChallengesProgressModel.builder()
                .userChallenge(enrollment)
                .amountContributed(amount)
                .newTotalAmount(newTotal)
                .transactionReference(transactionReference)
                .notes(notes)
                .build();
        challengesProgressRepository.save(entry);

        enrollment.setCurrentAmount(newTotal);
        if (newTotal.compareTo(enrollment.getTargetAmount()) >= 0) {
            enrollment.setStatus(Datatypes.ChallengeStatus.COMPLETED);
            enrollment.setCompletedAt(LocalDateTime.now());
        }

        return toUserChallengeWithLogs(userChallengesRepository.save(enrollment));
    }

    /**
     * Decline a challenge: drop any enrollment and record the opt-out, so the
     * challenge stops being offered to this user but can be rejoined later.
     */
    @Transactional
    public void decline(UUID userId, UUID challengeId) {
        if (!challengesRepository.existsById(challengeId)) {
            throw new ResourceNotFoundException("Challenge not found");
        }

        userChallengesRepository.findByUserIdAndChallengeId(userId, challengeId)
                .ifPresent(userChallengesRepository::delete);

        declinedChallengesRepository.findByUserIdAndChallengeId(userId, challengeId)
                .orElseGet(() -> {
                    DeclinedChallengesModel declined = new DeclinedChallengesModel();
                    declined.setUserId(userId);
                    declined.setChallengeId(challengeId);
                    return declinedChallengesRepository.save(declined);
                });
    }

    // ========================================================================
    // INTERNAL HELPERS
    // ========================================================================

    /**
     * Loads an enrollment and asserts it belongs to {@code userId}, so one user
     * can never read or mutate another user's challenge progress.
     */
    private UserChallengesModel requireOwnedEnrollment(UUID userId, UUID userChallengeId) {
        UserChallengesModel enrollment = userChallengesRepository.findById(userChallengeId)
                .orElseThrow(() -> new ResourceNotFoundException("Challenge enrollment not found"));
        if (!enrollment.getUserId().equals(userId)) {
            throw new ResourceNotFoundException("Challenge enrollment not found");
        }
        return enrollment;
    }

    /**
     * Builds the response DTO with targets fetched explicitly. The entity's
     * {@code targets} collection is LAZY, so touching it here would throw a
     * LazyInitializationException outside a transaction.
     */
    private ChallengesResponseDTO toChallengeWithTargets(ChallengesModel challenge) {
        List<ChallengesTargetResponseDTO> targets =
                challengesTargetRepository.findByChallengeIdOrderByTierLevelAsc(challenge.getId()).stream()
                        .map(ChallengeMapper::toTargetResponseDTO)
                        .toList();
        return ChallengeMapper.toChallengeResponseDTO(challenge, targets);
    }

    /**
     * Same reasoning as {@link #toChallengeWithTargets} — the ledger is loaded
     * from the progress repository instead of the LAZY {@code progressLogs}.
     */
    private UserChallengesResponseDTO toUserChallengeWithLogs(UserChallengesModel enrollment) {
        List<ChallengesProgressResponseDTO> logs =
                challengesProgressRepository
                        .findByUserChallengeIdOrderByCreatedAtDesc(enrollment.getId()).stream()
                        .map(ChallengeMapper::toProgressResponseDTO)
                        .toList();
        return ChallengeMapper.toUserChallengeResponseDTO(enrollment, logs);
    }
}
