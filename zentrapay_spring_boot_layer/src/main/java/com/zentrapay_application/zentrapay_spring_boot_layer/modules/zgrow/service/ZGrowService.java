package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto.ChallengeDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto.CompleteResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto.LiteracyContentDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto.PointsLedgerEntryDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto.RewardsSummaryDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.model.ChallengeModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.model.ChallengeParticipant;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.model.ContentCompletion;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.model.FinancialLiteracyContent;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.model.PointsLedger;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.model.UserRewardBalance;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.repository.ChallengeParticipantRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.repository.ChallengeRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.repository.ContentCompletionRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.repository.FinancialLiteracyContentRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.repository.PointsLedgerRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.repository.UserRewardBalanceRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * ZGrow: gamified savings challenges, financial literacy, and the points/
 * rewards ledger that ties them together (API contract §14).
 */
@Service
@Transactional
@RequiredArgsConstructor
public class ZGrowService {

    private static final Logger log = LoggerFactory.getLogger(ZGrowService.class);

    private final ChallengeRepository challengeRepository;
    private final ChallengeParticipantRepository challengeParticipantRepository;
    private final FinancialLiteracyContentRepository literacyContentRepository;
    private final ContentCompletionRepository contentCompletionRepository;
    private final PointsLedgerRepository pointsLedgerRepository;
    private final UserRewardBalanceRepository userRewardBalanceRepository;

    // ========================================================================
    // CHALLENGES — GET /api/zgrow/challenges[?category=]
    // ========================================================================

    @Transactional(readOnly = true)
    public List<ChallengeDTO> getActiveChallenges(UUID userId) {
        return toDtos(challengeRepository.findByStatus("ACTIVE"), userId);
    }

    @Transactional(readOnly = true)
    public List<ChallengeDTO> getChallengesByCategory(UUID userId, String category) {
        return toDtos(challengeRepository.findByCategoryAndStatus(category, "ACTIVE"), userId);
    }

    private List<ChallengeDTO> toDtos(List<ChallengeModel> challenges, UUID userId) {
        return challenges.stream().map(c -> toDto(c, userId)).toList();
    }

    private ChallengeDTO toDto(ChallengeModel challenge, UUID userId) {
        long participantsCount = challengeParticipantRepository.countByChallengeId(challenge.getChallengeId());
        var participation = challengeParticipantRepository
                .findByChallengeIdAndUserId(challenge.getChallengeId(), userId);
        return new ChallengeDTO(
                challenge.getChallengeId(),
                challenge.getTitle(),
                challenge.getDescription(),
                challenge.getCategory(),
                challenge.getDurationDays(),
                challenge.getPointsReward(),
                challenge.getDifficulty(),
                participantsCount,
                participation.isPresent(),
                participation.map(p -> (int) p.getProgressPercent()).orElse(0)
        );
    }

    // POST /api/zgrow/challenges/{challengeId}/join
    public ChallengeDTO joinChallenge(UUID userId, UUID challengeId) {
        ChallengeModel challenge = challengeRepository.findById(challengeId)
                .orElseThrow(() -> new RuntimeException("Challenge not found"));

        if (!challengeParticipantRepository.existsByChallengeIdAndUserId(challengeId, userId)) {
            ChallengeParticipant participant = new ChallengeParticipant();
            participant.setChallengeId(challengeId);
            participant.setUserId(userId);
            challengeParticipantRepository.save(participant);
            log.info("[ZGROW] userId={} joined challenge={}", userId, challengeId);
        }

        return toDto(challenge, userId);
    }

    // ========================================================================
    // FINANCIAL LITERACY — GET /api/zgrow/literacy, POST .../complete
    // ========================================================================

    @Transactional(readOnly = true)
    public List<LiteracyContentDTO> getLiteracyContent(UUID userId) {
        return literacyContentRepository.findByIsActiveTrue().stream()
                .map(content -> new LiteracyContentDTO(
                        content.getContentId(),
                        content.getTitle(),
                        content.getCategory(),
                        content.getContentUrl(),
                        content.getDurationMinutes(),
                        content.getPointsReward(),
                        contentCompletionRepository.existsByContentIdAndUserId(content.getContentId(), userId)
                ))
                .toList();
    }

    // POST /api/zgrow/literacy/{contentId}/complete — idempotent per the
    // unique (content_id, user_id) constraint on content_completions.
    public CompleteResponseDTO completeLiteracyContent(UUID userId, UUID contentId) {
        var existing = contentCompletionRepository.findByContentIdAndUserId(contentId, userId);
        if (existing.isPresent()) {
            return new CompleteResponseDTO(existing.get().getPointsEarned());
        }

        FinancialLiteracyContent content = literacyContentRepository.findById(contentId)
                .orElseThrow(() -> new RuntimeException("Content not found"));

        int points = content.getPointsReward() == null ? 0 : content.getPointsReward();

        ContentCompletion completion = new ContentCompletion();
        completion.setContentId(contentId);
        completion.setUserId(userId);
        completion.setPointsEarned(points);
        contentCompletionRepository.save(completion);

        awardPoints(userId, points, "Completed: " + content.getTitle(), "LITERACY_CONTENT", contentId);
        log.info("[ZGROW] userId={} completed literacy content={}, points={}", userId, contentId, points);

        return new CompleteResponseDTO(points);
    }

    // ========================================================================
    // REWARDS — GET /api/zgrow/rewards
    // ========================================================================

    @Transactional(readOnly = true)
    public RewardsSummaryDTO getRewards(UUID userId) {
        UserRewardBalance balance = userRewardBalanceRepository.findById(userId).orElse(null);
        List<PointsLedgerEntryDTO> recentLedger = pointsLedgerRepository
                .findByUserIdOrderByCreatedAtDesc(userId, PageRequest.of(0, 10)).stream()
                .map(entry -> new PointsLedgerEntryDTO(entry.getPoints(), entry.getReason(), entry.getCreatedAt()))
                .toList();

        return new RewardsSummaryDTO(
                balance == null ? 0 : balance.getTotalPoints(),
                balance == null ? "BRONZE" : balance.getTier(),
                recentLedger
        );
    }

    /**
     * Appends a ledger row and transactionally maintains the running total in
     * user_reward_balances (points_ledger stays the source of truth; the
     * balance row exists purely so reads don't SUM() the whole ledger).
     */
    private void awardPoints(UUID userId, int points, String reason, String referenceType, UUID referenceId) {
        PointsLedger ledgerEntry = new PointsLedger();
        ledgerEntry.setUserId(userId);
        ledgerEntry.setPoints(points);
        ledgerEntry.setReason(reason);
        ledgerEntry.setReferenceType(referenceType);
        ledgerEntry.setReferenceId(referenceId);
        pointsLedgerRepository.save(ledgerEntry);

        UserRewardBalance balance = userRewardBalanceRepository.findById(userId).orElseGet(() -> {
            UserRewardBalance fresh = new UserRewardBalance();
            fresh.setUserId(userId);
            return fresh;
        });
        int newTotal = balance.getTotalPoints() + points;
        balance.setTotalPoints(newTotal);
        balance.setTier(tierFor(newTotal));
        userRewardBalanceRepository.save(balance);
    }

    private String tierFor(int totalPoints) {
        if (totalPoints >= 2000) return "PLATINUM";
        if (totalPoints >= 500) return "GOLD";
        if (totalPoints >= 100) return "SILVER";
        return "BRONZE";
    }
}
