package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.dto.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.service.ZBankingService;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.AuthenticatedUser;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.CurrentUser;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * ZBanking (Savings & Loans) Controller — API_CONTRACT.md §13.
 */
@RestController
@RequestMapping("/api/zbanking")
@RequiredArgsConstructor
public class ZBankingController {

    private final ZBankingService zBankingService;

    @GetMapping("/savings")
    public ResponseEntity<ApiResponse<List<SavingsResponseDTO>>> getSavings(@CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(zBankingService.getUserSavings(user.userId()), "Savings retrieved successfully"));
    }

    @PostMapping("/savings")
    public ResponseEntity<ApiResponse<SavingsResponseDTO>> createSavings(@CurrentUser AuthenticatedUser user,
                                                                          @Valid @RequestBody SavingsRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(zBankingService.createSavingsAccount(user.userId(), request), "Savings account created successfully"));
    }

    @PostMapping("/savings/{savingsId}/deposit")
    public ResponseEntity<ApiResponse<SavingsResponseDTO>> depositToSavings(@CurrentUser AuthenticatedUser user,
                                                                             @PathVariable UUID savingsId,
                                                                             @Valid @RequestBody AmountRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(
                zBankingService.depositToSavings(user.userId(), savingsId, request.amount()), "Deposit successful"));
    }

    @PostMapping("/savings/{savingsId}/withdraw")
    public ResponseEntity<ApiResponse<SavingsResponseDTO>> withdrawFromSavings(@CurrentUser AuthenticatedUser user,
                                                                                @PathVariable UUID savingsId,
                                                                                @Valid @RequestBody AmountRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(
                zBankingService.withdrawFromSavings(user.userId(), savingsId, request.amount()), "Withdrawal successful"));
    }

    @GetMapping("/loans")
    public ResponseEntity<ApiResponse<List<LoanResponseDTO>>> getLoans(@CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(zBankingService.getUserLoans(user.userId()), "Loans retrieved successfully"));
    }

    @PostMapping("/loans/apply")
    public ResponseEntity<ApiResponse<LoanResponseDTO>> applyLoan(@CurrentUser AuthenticatedUser user,
                                                                   @Valid @RequestBody LoanRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(zBankingService.applyForLoan(user.userId(), request), "Loan application submitted"));
    }

    @PostMapping("/loans/{loanId}/repay")
    public ResponseEntity<ApiResponse<LoanResponseDTO>> repayLoan(@CurrentUser AuthenticatedUser user,
                                                                   @PathVariable UUID loanId,
                                                                   @Valid @RequestBody AmountRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(
                zBankingService.repayLoan(user.userId(), loanId, request.amount()), "Loan repayment processed"));
    }

    @GetMapping("/insights")
    public ResponseEntity<ApiResponse<InsightsDTO>> getInsights(@CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(zBankingService.getInsights(user.userId()), "Insights retrieved successfully"));
    }

    @GetMapping("/budget")
    public ResponseEntity<ApiResponse<BudgetDTO>> getBudget(@CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(zBankingService.getBudget(user.userId()), "Budget retrieved successfully"));
    }

    @PutMapping("/budget")
    public ResponseEntity<ApiResponse<BudgetDTO>> updateBudget(@CurrentUser AuthenticatedUser user,
                                                                @Valid @RequestBody BudgetUpdateRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(zBankingService.updateBudget(user.userId(), request), "Budget updated successfully"));
    }
}
