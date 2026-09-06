package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto.RewardsDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto.TutorialsDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.service.ZGrowServices;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.AuthenticatedUser;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * In-app notifications — backs the home screen's notification-bell overlay.
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
        return ResponseEntity.ok(ApiResponse.success(tutorials, "Rewards retrieved"));
    }
}
