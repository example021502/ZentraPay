package com.zentrapay.backend.controller;

import com.zentrapay.backend.dto.common.ApiResponse;
import com.zentrapay.backend.dto.savings.SavingsGoalDTOs.AmountRequest;
import com.zentrapay.backend.dto.savings.SavingsGoalDTOs.CreateGoalRequest;
import com.zentrapay.backend.dto.savings.SavingsGoalDTOs.GoalDTO;
import com.zentrapay.backend.security.AuthenticatedUser;
import com.zentrapay.backend.security.CurrentUser;
import com.zentrapay.backend.service.savings.SavingsGoalService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Savings goals ("Save Goal").
 * <pre>
 * GET  /api/zbanking/savings                   my goals with their progress
 * POST /api/zbanking/savings                   create a goal (optionally funded from my wallet)
 * POST /api/zbanking/savings/{id}/deposit      move money from my wallet into the goal
 * POST /api/zbanking/savings/{id}/withdraw     move money from the goal back to my wallet
 * </pre>
 */
@RestController
@RequestMapping("/api/zbanking/savings")
@RequiredArgsConstructor
public class SavingsGoalsController {

    private final SavingsGoalService savingsGoalService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<GoalDTO>>> list(@CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(savingsGoalService.myGoals(user.getUserId()), "Savings goals retrieved"));
    }

    @PostMapping({"", "/create"})
    public ResponseEntity<ApiResponse<GoalDTO>> create(@CurrentUser AuthenticatedUser user,
                                                       @Valid @RequestBody CreateGoalRequest request) {
        return ResponseEntity.ok(ApiResponse.success(savingsGoalService.create(user.getUserId(), request), "Savings goal created"));
    }

    @PostMapping("/{goalId}/deposit")
    public ResponseEntity<ApiResponse<GoalDTO>> deposit(@CurrentUser AuthenticatedUser user, @PathVariable UUID goalId,
                                                        @Valid @RequestBody AmountRequest request) {
        return ResponseEntity.ok(ApiResponse.success(savingsGoalService.deposit(user.getUserId(), goalId, request.amount()), "Money saved"));
    }

    @PostMapping("/{goalId}/withdraw")
    public ResponseEntity<ApiResponse<GoalDTO>> withdraw(@CurrentUser AuthenticatedUser user, @PathVariable UUID goalId,
                                                         @Valid @RequestBody AmountRequest request) {
        return ResponseEntity.ok(ApiResponse.success(savingsGoalService.withdraw(user.getUserId(), goalId, request.amount()), "Money withdrawn"));
    }
}
