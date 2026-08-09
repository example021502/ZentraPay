package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto.ChallengeDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto.CompleteResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto.LiteracyContentDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto.RewardsSummaryDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.service.ZGrowService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * ZGrow: gamified savings challenges, financial literacy, and rewards
 * (API contract §14).
 */
@RestController
@RequestMapping("/api/zgrow")
@RequiredArgsConstructor
public class ZGrowController {

    private final ZGrowService zGrowService;

    @GetMapping("/challenges")
    public ResponseEntity<ApiResponse<List<ChallengeDTO>>> getChallenges(
            Authentication authentication,
            @RequestParam(required = false) String category) {
        UUID userId = UUID.fromString(authentication.getName());
        List<ChallengeDTO> challenges = category == null
                ? zGrowService.getActiveChallenges(userId)
                : zGrowService.getChallengesByCategory(userId, category);
        return ResponseEntity.ok(ApiResponse.success(challenges, "Challenges retrieved"));
    }

    @PostMapping("/challenges/{challengeId}/join")
    public ResponseEntity<ApiResponse<ChallengeDTO>> joinChallenge(
            Authentication authentication,
            @PathVariable UUID challengeId) {
        UUID userId = UUID.fromString(authentication.getName());
        return ResponseEntity.ok(ApiResponse.success(
                zGrowService.joinChallenge(userId, challengeId),
                "Challenge joined"));
    }

    @GetMapping("/literacy")
    public ResponseEntity<ApiResponse<List<LiteracyContentDTO>>> getLiteracyContent(
            Authentication authentication) {
        UUID userId = UUID.fromString(authentication.getName());
        return ResponseEntity.ok(ApiResponse.success(
                zGrowService.getLiteracyContent(userId), "Literacy content retrieved"));
    }

    @PostMapping("/literacy/{contentId}/complete")
    public ResponseEntity<ApiResponse<CompleteResponseDTO>> completeLiteracyContent(
            Authentication authentication,
            @PathVariable UUID contentId) {
        UUID userId = UUID.fromString(authentication.getName());
        return ResponseEntity.ok(ApiResponse.success(
                zGrowService.completeLiteracyContent(userId, contentId), "Content completed"));
    }

    @GetMapping("/rewards")
    public ResponseEntity<ApiResponse<RewardsSummaryDTO>> getRewards(Authentication authentication) {
        UUID userId = UUID.fromString(authentication.getName());
        return ResponseEntity.ok(ApiResponse.success(
                zGrowService.getRewards(userId), "Rewards retrieved"));
    }
}
