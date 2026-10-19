package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.Datatypes;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.service.ZGrowServices;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.AuthenticatedUser;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.CurrentUser;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * ZGrow — the "Grow" tab: rewards, tutorials and savings challenges.
 * <p>
 * GET    /api/zgrow/rewards                 -> rewards catalog
 * GET    /api/zgrow/tutorials               -> tutorials catalog
 * GET    /api/zgrow/challenges              -> active challenges (optional ?category=)
 * GET    /api/zgrow/challenges/{id}         -> one challenge with its target tiers
 * GET    /api/zgrow/challenges/declined     -> ids this user declined
 * POST   /api/zgrow/challenges/enroll       -> join a challenge
 * POST   /api/zgrow/challenges/{id}/progress-> log a contribution
 * POST   /api/zgrow/challenges/{id}/decline -> decline a challenge
 * GET    /api/zgrow/myChallenges            -> the caller's enrollments
 * GET    /api/zgrow/myChallenges/{id}       -> one of the caller's enrollments
 */
@RestController
@RequestMapping("/api/zgrow")
@RequiredArgsConstructor
public class ZGrowController {

    private final ZGrowServices zGrowServices;

    @GetMapping("/rewards")
    public ResponseEntity<ApiResponse<List<RewardsDTO>>> rewardsList(
            @CurrentUser AuthenticatedUser user) {
        List<RewardsDTO> rewards = zGrowServices.listRewards();
        return ResponseEntity.ok(ApiResponse.success(rewards, "Rewards retrieved"));
    }

    @GetMapping("/tutorials")
    public ResponseEntity<ApiResponse<List<TutorialsDTO>>> tutorialsList(
            @CurrentUser AuthenticatedUser user) {
        List<TutorialsDTO> tutorials = zGrowServices.listTutorials();
        return ResponseEntity.ok(ApiResponse.success(tutorials, "Tutorials retrieved"));
    }

    // ========================================================================
    // CHALLENGES
    // ========================================================================

    /** Active challenges; pass {@code ?category=SAVINGS} to filter by category. */
    @GetMapping("/challenges")
    public ResponseEntity<ApiResponse<List<ChallengesResponseDTO>>> challenges(
            @CurrentUser AuthenticatedUser user,
            @RequestParam(required = false) Datatypes.ChallengeCategory category) {
        List<ChallengesResponseDTO> challenges = category == null
                ? zGrowServices.listActiveChallenges()
                : zGrowServices.listActiveChallengesByCategory(category);
        return ResponseEntity.ok(ApiResponse.success(challenges, "Challenges retrieved"));
    }

    /**
     * Persisted ZGrow toggle for the caller. The app reads this on load to
     * decide whether the challenges section is shown and tracked; the gamified
     * switch writes it back.
     */
    @GetMapping("/gamification")
    public ResponseEntity<ApiResponse<GamificationSettingsDTO>> gamification(
            @CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(
                zGrowServices.getGamificationSettings(user.getUserId()),
                "Gamification settings retrieved"));
    }

    /** Records a toggle change; echoes the stored state for the client. */
    @PutMapping("/gamification")
    public ResponseEntity<ApiResponse<GamificationSettingsDTO>> updateGamification(
            @CurrentUser AuthenticatedUser user,
            @Valid @RequestBody UpdateGamificationSettingsRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(
                zGrowServices.updateGamificationSettings(user.getUserId(), request.challengesEnabled()),
                "Gamification settings updated"));
    }

    /**
     * Per-currency savings buckets. The ZGrow hero card's overall-savings
     * figure is the {@code totalAmount} of the bucket in the user's wallet
     * currency — computed server-side so the client never sums money itself.
     */
    @GetMapping("/savings")
    public ResponseEntity<ApiResponse<List<SavingsSummaryDTO>>> savings(
            @CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(
                zGrowServices.getSavingsSummary(user.getUserId()),
                "Savings retrieved"));
    }

    @GetMapping("/challenges/declined")
    public ResponseEntity<ApiResponse<List<UUID>>> declinedChallenges(@CurrentUser AuthenticatedUser user) {
        List<UUID> declined = zGrowServices.listDeclinedChallengeIds(user.getUserId());
        return ResponseEntity.ok(ApiResponse.success(declined, "Declined challenges retrieved"));
    }

    @GetMapping("/challenges/{challengeId}")
    public ResponseEntity<ApiResponse<ChallengesResponseDTO>> challenge(
            @CurrentUser AuthenticatedUser user,
            @PathVariable UUID challengeId) {
        ChallengesResponseDTO challenge = zGrowServices.getChallenge(challengeId);
        return ResponseEntity.ok(ApiResponse.success(challenge, "Challenge retrieved"));
    }

    @PostMapping("/challenges/enroll")
    public ResponseEntity<ApiResponse<UserChallengesResponseDTO>> enroll(
            @CurrentUser AuthenticatedUser user,
            @Valid @RequestBody EnrollChallengeRequestDTO request) {
        UserChallengesResponseDTO enrollment = zGrowServices.enroll(user.getUserId(), request.challengeId());
        return ResponseEntity.ok(ApiResponse.success(enrollment, "Challenge enrolled"));
    }

    @PostMapping("/challenges/{userChallengeId}/progress")
    public ResponseEntity<ApiResponse<UserChallengesResponseDTO>> logProgress(
            @CurrentUser AuthenticatedUser user,
            @PathVariable UUID userChallengeId,
            @Valid @RequestBody LogProgressRequestDTO request) {
        UserChallengesResponseDTO updated = zGrowServices.logProgress(
                user.getUserId(), user.getCountryCode(), userChallengeId, request.amount(),
                request.transactionReference(), request.notes());
        return ResponseEntity.ok(ApiResponse.success(updated, "Progress logged"));
    }

    @PostMapping("/challenges/{challengeId}/decline")
    public ResponseEntity<ApiResponse<String>> decline(
            @CurrentUser AuthenticatedUser user,
            @PathVariable UUID challengeId) {
        zGrowServices.decline(user.getUserId(), challengeId);
        return ResponseEntity.ok(ApiResponse.success("Challenge declined"));
    }

    @GetMapping("/myChallenges")
    public ResponseEntity<ApiResponse<List<UserChallengesResponseDTO>>> myChallenges(
            @CurrentUser AuthenticatedUser user) {
        List<UserChallengesResponseDTO> mine = zGrowServices.listMyChallenges(user.getUserId());
        return ResponseEntity.ok(ApiResponse.success(mine, "My challenges retrieved"));
    }

    @GetMapping("/myChallenges/{userChallengeId}")
    public ResponseEntity<ApiResponse<UserChallengesResponseDTO>> myChallenge(
            @CurrentUser AuthenticatedUser user,
            @PathVariable UUID userChallengeId) {
        UserChallengesResponseDTO mine = zGrowServices.getMyChallenge(user.getUserId(), userChallengeId);
        return ResponseEntity.ok(ApiResponse.success(mine, "Challenge retrieved"));
    }
}
