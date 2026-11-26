package com.zentrapay.backend.controller;

import com.zentrapay.backend.dto.bank.BankingInsightDTOs.BudgetDTO;
import com.zentrapay.backend.dto.bank.BankingInsightDTOs.InsightsDTO;
import com.zentrapay.backend.dto.bank.BankingInsightDTOs.SetBudgetRequest;
import com.zentrapay.backend.dto.common.ApiResponse;
import com.zentrapay.backend.security.AuthenticatedUser;
import com.zentrapay.backend.security.CurrentUser;
import com.zentrapay.backend.service.bank.BankingInsightsService;
import com.zentrapay.backend.service.common.Datatypes;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.jspecify.annotations.NonNull;
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

    @GetMapping("/insights/{period}")
    public ResponseEntity<ApiResponse<InsightsDTO>> insights(@NonNull @CurrentUser AuthenticatedUser user, @PathVariable() Datatypes.BudgetPeriod period) {
        return ResponseEntity.ok(ApiResponse.success(insightsService.insights(user.getUserId(), period), "Insights retrieved"));
    }

    @GetMapping("/budget/{currencyCode}/{period}")
    public ResponseEntity<ApiResponse<BudgetDTO>> budget(@NonNull @CurrentUser AuthenticatedUser user, @PathVariable String currencyCode, @PathVariable Datatypes.BudgetPeriod period) {
        return ResponseEntity.ok(ApiResponse.success(insightsService.budget(user.getUserId(), currencyCode, period), "Budget retrieved"));
    }

    @PutMapping("/budget/set")
    public ResponseEntity<ApiResponse<BudgetDTO>> setBudget(@CurrentUser @NonNull AuthenticatedUser user,
                                                            @Valid @RequestBody @NonNull SetBudgetRequest request) {
        return ResponseEntity.ok(ApiResponse.success(insightsService.setBudget(user.getUserId(), request.limit(), request.currencyCode(), request.period()), "Budget saved"));
    }
}
