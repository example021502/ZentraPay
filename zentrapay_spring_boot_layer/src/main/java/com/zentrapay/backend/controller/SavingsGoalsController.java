package com.zentrapay.backend.controller;

import com.zentrapay.backend.dto.common.ApiResponse;
import com.zentrapay.backend.dto.savings.SavingsGoalDTOs.ActivityDTO;
import com.zentrapay.backend.dto.savings.SavingsGoalDTOs.AmountRequest;
import com.zentrapay.backend.dto.savings.SavingsGoalDTOs.AutoSaveRequest;
import com.zentrapay.backend.dto.savings.SavingsGoalDTOs.CreateGoalRequest;
import com.zentrapay.backend.dto.savings.SavingsGoalDTOs.DeletedGoalDTO;
import com.zentrapay.backend.dto.savings.SavingsGoalDTOs.FreezeRequest;
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
 * GET    /api/zbanking/savings                   my goals with their progress, freeze and auto-save state
 * GET    /api/zbanking/savings/activity?limit=   my recent goal deposits / withdrawals / automatic saves
 * POST   /api/zbanking/savings                   create a goal (optionally funded from my wallet)
 * POST   /api/zbanking/savings/{id}/deposit      move money from my wallet into the goal
 * POST   /api/zbanking/savings/{id}/withdraw     move money from the goal back to my wallet
 * POST   /api/zbanking/savings/{id}/freeze       stop saving into the goal for 1-7 days  {days}
 * POST   /api/zbanking/savings/{id}/unfreeze     end a freeze early
 * PUT    /api/zbanking/savings/{id}/auto-save    save {amount} every {frequency} (DAILY | WEEKLY | MONTHLY)
 * DELETE /api/zbanking/savings/{id}/auto-save    turn the automatic save off
 * DELETE /api/zbanking/savings/{id}              delete the goal; its savings go back to my wallet
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

    @GetMapping("/activity")
    public ResponseEntity<ApiResponse<List<ActivityDTO>>> activity(@CurrentUser AuthenticatedUser user,
                                                                   @RequestParam(defaultValue = "30") int limit) {
        return ResponseEntity.ok(ApiResponse.success(savingsGoalService.recentActivity(user.getUserId(), limit), "Savings activity retrieved"));
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

    @PostMapping("/{goalId}/freeze")
    public ResponseEntity<ApiResponse<GoalDTO>> freeze(@CurrentUser AuthenticatedUser user, @PathVariable UUID goalId,
                                                       @Valid @RequestBody FreezeRequest request) {
        return ResponseEntity.ok(ApiResponse.success(savingsGoalService.freeze(user.getUserId(), goalId, request.days()), "Goal frozen"));
    }

    @PostMapping("/{goalId}/unfreeze")
    public ResponseEntity<ApiResponse<GoalDTO>> unfreeze(@CurrentUser AuthenticatedUser user, @PathVariable UUID goalId) {
        return ResponseEntity.ok(ApiResponse.success(savingsGoalService.unfreeze(user.getUserId(), goalId), "Goal unfrozen"));
    }

    @PutMapping("/{goalId}/auto-save")
    public ResponseEntity<ApiResponse<GoalDTO>> setAutoSave(@CurrentUser AuthenticatedUser user, @PathVariable UUID goalId,
                                                            @Valid @RequestBody AutoSaveRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                savingsGoalService.setAutoSave(user.getUserId(), goalId, request.amount(), request.frequency()), "Auto-save is on"));
    }

    @DeleteMapping("/{goalId}/auto-save")
    public ResponseEntity<ApiResponse<GoalDTO>> disableAutoSave(@CurrentUser AuthenticatedUser user, @PathVariable UUID goalId) {
        return ResponseEntity.ok(ApiResponse.success(savingsGoalService.disableAutoSave(user.getUserId(), goalId), "Auto-save is off"));
    }

    @DeleteMapping("/{goalId}")
    public ResponseEntity<ApiResponse<DeletedGoalDTO>> delete(@CurrentUser AuthenticatedUser user, @PathVariable UUID goalId) {
        return ResponseEntity.ok(ApiResponse.success(savingsGoalService.delete(user.getUserId(), goalId), "Goal deleted"));
    }
}
