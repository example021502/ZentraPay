package com.zentrapay.backend.controller;

import com.zentrapay.backend.dto.common.ApiResponse;
import com.zentrapay.backend.dto.loan.LoanDTOs.*;
import com.zentrapay.backend.security.AuthenticatedUser;
import com.zentrapay.backend.security.CurrentUser;
import com.zentrapay.backend.service.loan.LoanService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * ZBank micro-loans.
 * <pre>
 * GET  /api/zbanking/loans              my loans and applications
 * GET  /api/zbanking/loans/eligibility  what I may borrow (KYC level, risk grade, limits)
 * POST /api/zbanking/loans/apply        submit an application (approved loans are paid into the wallet)
 * POST /api/zbanking/loans/{id}/repay   pay back part or all of a loan from my wallet
 * </pre>
 */
@RestController
@RequestMapping("/api/zbanking/loans")
@RequiredArgsConstructor
public class LoansController {

    private final LoanService loanService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<LoanDTO>>> myLoans(@CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(loanService.myLoans(user.getUserId()), "Loans retrieved"));
    }

    @GetMapping("/eligibility")
    public ResponseEntity<ApiResponse<LoanEligibilityDTO>> eligibility(@CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(loanService.eligibility(user.getUserId()), "Eligibility retrieved"));
    }

    @PostMapping("/apply")
    public ResponseEntity<ApiResponse<LoanDTO>> apply(@CurrentUser AuthenticatedUser user,
                                                      @RequestBody LoanApplicationRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(loanService.apply(user.getUserId(), request), "Application submitted"));
    }

    @PostMapping("/{loanId}/repay")
    public ResponseEntity<ApiResponse<LoanDTO>> repay(@CurrentUser AuthenticatedUser user,
                                                      @PathVariable java.util.UUID loanId,
                                                      @RequestBody RepayRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(loanService.repay(user.getUserId(), loanId, request.amount()), "Repayment received"));
    }
}
