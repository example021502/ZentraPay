package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.model.ChallengeModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.repository.ChallengeRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * Service for ZGrow: gamified savings challenges, rewards, financial literacy.
 */
@Service
@Transactional
public class ZGrowService {

    private static final Logger log = LoggerFactory.getLogger(ZGrowService.class);

    private final ChallengeRepository challengeRepository;

    public ZGrowService(ChallengeRepository challengeRepository) {
        this.challengeRepository = challengeRepository;
    }

    /**
     * Retrieves all active challenges.
     */
    @Transactional(readOnly = true)
    public List<ChallengeModel> getActiveChallenges() {
        log.info("[ZGROW] Fetching active challenges");
        return challengeRepository.findByStatus("ACTIVE");
    }

    /**
     * Retrieves challenges by category.
     */
    @Transactional(readOnly = true)
    public List<ChallengeModel> getChallengesByCategory(String category) {
        log.info("[ZGROW] Fetching challenges by category={}", category);
        return challengeRepository.findByCategoryAndStatus(category, "ACTIVE");
    }

    /**
     * Creates a new challenge (admin only).
     */
    public ChallengeModel createChallenge(String title, String description, String category,
                                         Integer durationDays, Integer pointsReward, String difficulty) {
        log.info("[ZGROW] Creating challenge: title={}", title);

        ChallengeModel challenge = new ChallengeModel();
        challenge.setTitle(title);
        challenge.setDescription(description);
        challenge.setCategory(category);
        challenge.setDurationDays(durationDays);
        challenge.setPointsReward(pointsReward);
        challenge.setDifficulty(difficulty);
        challenge.setStatus("ACTIVE");
        challenge.setParticipantsCount(0);

        return challengeRepository.save(challenge);
    }

    /**
     * Join a challenge.
     */
    public ChallengeModel joinChallenge(UUID challengeId) {
        log.info("[ZGROW] Joining challenge={}", challengeId);

        ChallengeModel challenge = challengeRepository.findById(challengeId)
                .orElseThrow(() -> new RuntimeException("Challenge not found"));

        challenge.setParticipantsCount(challenge.getParticipantsCount() + 1);
        return challengeRepository.save(challenge);
    }
}