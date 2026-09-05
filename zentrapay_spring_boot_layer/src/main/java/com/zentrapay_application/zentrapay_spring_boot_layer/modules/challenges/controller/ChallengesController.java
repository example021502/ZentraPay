package com.zentrapay_application.zentrapay_spring_boot_layer.modules.challenges.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.challenges.dto.ChallengesResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.challenges.dto.RewardsDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.challenges.service.ChallengesServices;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.AuthenticatedUser;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * In-app notifications — backs the home screen's notification-bell overlay.
 */
@RestController
@RequestMapping("/api/challenges")
@RequiredArgsConstructor
public class ChallengesController {

    private final ChallengesServices challengesServices;

    @GetMapping("/rewards")
    public ResponseEntity<ApiResponse<List<RewardsDTO>>> list(
            @CurrentUser AuthenticatedUser user) {
        List<RewardsDTO> rewards = challengesServices.list();
        return ResponseEntity.ok(ApiResponse.success(rewards, "Rewards retrieved"));
    }
}
