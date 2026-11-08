package com.zentrapay.backend.controller;

import com.zentrapay.backend.dto.bank.BankingInsightDTOs.BudgetDTO;
import com.zentrapay.backend.dto.bank.BankingInsightDTOs.InsightsDTO;
import com.zentrapay.backend.dto.bank.BankingInsightDTOs.SetBudgetRequest;
import com.zentrapay.backend.dto.common.ApiResponse;
import com.zentrapay.backend.security.AuthenticatedUser;
import com.zentrapay.backend.security.CurrentUser;
import com.zentrapay.backend.service.bank.BankingInsightsService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * ZBank spending insights and the monthly budget.
 * <pre>
 * GET /api/zbanking/insights   this month's spend, income and top spend categories
 * GET /api/zbanking/budget     monthly limit, spent so far, what is left
 * PUT /api/zbanking/budget     set the monthly limit (0 clears it)
 * </pre>
 */
@RestController
@RequestMapping("/api/zbanking")
@RequiredArgsConstructor
public class BankingInsightsController {

    private final BankingInsightsService insightsService;

    @GetMapping("/insights")
    public ResponseEntity<ApiResponse<InsightsDTO>> insights(@CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(insightsService.insights(user.getUserId()), "Insights retrieved"));
    }

    @GetMapping("/budget")
    public ResponseEntity<ApiResponse<BudgetDTO>> budget(@CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(insightsService.budget(user.getUserId()), "Budget retrieved"));
    }

    @PutMapping("/budget")
    public ResponseEntity<ApiResponse<BudgetDTO>> setBudget(@CurrentUser AuthenticatedUser user,
                                                            @Valid @RequestBody SetBudgetRequest request) {
        return ResponseEntity.ok(ApiResponse.success(insightsService.setBudget(user.getUserId(), request.monthlyLimit()), "Budget saved"));
    }
}
