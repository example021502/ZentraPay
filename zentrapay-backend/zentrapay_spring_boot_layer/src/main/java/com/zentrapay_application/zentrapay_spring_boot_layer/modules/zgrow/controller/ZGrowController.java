package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.service.ZGrowService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * ZGrow Controller - Gamified savings challenges, rewards, financial literacy
 */
@RestController
@RequestMapping("/api/zgrow")
public class ZGrowController {

    private final ZGrowService zGrowService;

    public ZGrowController(ZGrowService zGrowService) {
        this.zGrowService = zGrowService;
    }

    /**
     * Get all active challenges.
     */
    @GetMapping("/challenges")
    public ResponseEntity<ApiResponse<List<?>>> getActiveChallenges() {
        return ResponseEntity.ok(ApiResponse.success(
                zGrowService.getActiveChallenges(),
                "Active challenges retrieved"));
    }

    /**
     * Get challenges by category.
     */
    @GetMapping("/challenges/category/{category}")
    public ResponseEntity<ApiResponse<List<?>>> getChallengesByCategory(@PathVariable String category) {
        return ResponseEntity.ok(ApiResponse.success(
                zGrowService.getChallengesByCategory(category),
                "Challenges by category retrieved"));
    }

    /**
     * Join a challenge.
     */
    @PostMapping("/challenges/{challengeId}/join")
    public ResponseEntity<ApiResponse<Object>> joinChallenge(Authentication authentication,
                                                             @PathVariable UUID challengeId) {
        UUID userId = UUID.fromString(authentication.getName());
        return ResponseEntity.ok(ApiResponse.success(
                zGrowService.joinChallenge(challengeId),
                "Challenge joined successfully"));
    }

    /**
     * Get user's rewards and points.
     */
    @GetMapping("/rewards")
    public ResponseEntity<ApiResponse<Object>> getRewards(Authentication authentication) {
        UUID userId = UUID.fromString(authentication.getName());
        // TODO: Implement rewards retrieval
        return ResponseEntity.ok(ApiResponse.success(null, "Rewards retrieved"));
    }

    /**
     * Get financial literacy content.
     */
    @GetMapping("/literacy")
    public ResponseEntity<ApiResponse<Object>> getLiteracyContent() {
        // TODO: Implement financial literacy content
        return ResponseEntity.ok(ApiResponse.success(null, "Literacy content retrieved"));
    }
}