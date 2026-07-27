package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.dto.SavingsRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.dto.SavingsResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.model.SavingsModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.service.ZBankingService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.Authentication;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * ZBank Lite Controller
 * Digital savings & micro-loans, AI-powered financial insights, auto-budgeting
 */
@RestController
@RequestMapping("/api/zbanking")
public class ZBankingController {

    private static final Logger log = LoggerFactory.getLogger(ZBankingController.class);

    private final ZBankingService zBankingService;

    public ZBankingController(ZBankingService zBankingService) {
        this.zBankingService = zBankingService;
    }

    /**
     * Get all savings accounts for the authenticated user.
     */
    @GetMapping("/savings")
    public ResponseEntity<ApiResponse<List<SavingsResponseDTO>>> getSavings(Authentication authentication) {
        UUID userId = UUID.fromString(authentication.getName());
        log.info("[SPRING_CTRL] Getting savings for userId={}", userId);

        List<SavingsModel> savings = zBankingService.getUserSavings(userId);

        List<SavingsResponseDTO> response = savings.stream()
                .map(this::mapToResponseDTO)
                .toList();

        return ResponseEntity.ok(ApiResponse.success(response, "Savings retrieved successfully"));
    }

    /**
     * Create a new savings account.
     */
    @PostMapping("/savings/create")
    public ResponseEntity<ApiResponse<SavingsResponseDTO>> createSavings(
            Authentication authentication,
            @RequestBody SavingsRequestDTO request) {
        UUID userId = UUID.fromString(authentication.getName());
        log.info("[SPRING_CTRL] Creating savings for userId={}", userId);

        SavingsModel savings = zBankingService.createSavingsAccount(userId, request);
        return ResponseEntity.ok(ApiResponse.success(mapToResponseDTO(savings), "Savings account created successfully"));
    }

    /**
     * Deposit funds into a savings account.
     */
    @PostMapping("/savings/{savingsId}/deposit")
    public ResponseEntity<ApiResponse<SavingsResponseDTO>> depositToSavings(
            @PathVariable UUID savingsId,
            @RequestParam BigDecimal amount) {
        log.info("[SPRING_CTRL] Depositing {} to savingsId={}", amount, savingsId);

        SavingsModel savings = zBankingService.depositToSavings(savingsId, amount);
        return ResponseEntity.ok(ApiResponse.success(mapToResponseDTO(savings), "Deposit successful"));
    }

    /**
     * Withdraw funds from a savings account.
     */
    @PostMapping("/savings/{savingsId}/withdraw")
    public ResponseEntity<ApiResponse<SavingsResponseDTO>> withdrawFromSavings(
            @PathVariable UUID savingsId,
            @RequestParam BigDecimal amount) {
        log.info("[SPRING_CTRL] Withdrawing {} from savingsId={}", amount, savingsId);

        SavingsModel savings = zBankingService.withdrawFromSavings(savingsId, amount);
        return ResponseEntity.ok(ApiResponse.success(mapToResponseDTO(savings), "Withdrawal successful"));
    }

    /**
     * Get loans for the authenticated user.
     */
    @GetMapping("/loans")
    public ResponseEntity<ApiResponse<List<?>>> getLoans(Authentication authentication) {
        UUID userId = UUID.fromString(authentication.getName());
        log.info("[SPRING_CTRL] Getting loans for userId={}", userId);

        // TODO: Implement loan retrieval
        return ResponseEntity.ok(ApiResponse.success(List.of(), "Loans retrieved successfully"));
    }

    /**
     * Apply for a loan.
     */
    @PostMapping("/loans/apply")
    public ResponseEntity<ApiResponse<Object>> applyLoan(
            Authentication authentication,
            @RequestBody Object request) {
        UUID userId = UUID.fromString(authentication.getName());
        log.info("[SPRING_CTRL] Loan application for userId={}", userId);

        // TODO: Implement loan application logic
        return ResponseEntity.ok(ApiResponse.success(null, "Loan application submitted"));
    }

    /**
     * Get budget information.
     */
    @GetMapping("/budget")
    public ResponseEntity<ApiResponse<Object>> getBudget(Authentication authentication) {
        UUID userId = UUID.fromString(authentication.getName());
        log.info("[SPRING_CTRL] Getting budget for userId={}", userId);

        // TODO: Implement budget retrieval
        return ResponseEntity.ok(ApiResponse.success(null, "Budget retrieved successfully"));
    }

    /**
     * Get AI-powered financial insights.
     */
    @GetMapping("/insights")
    public ResponseEntity<ApiResponse<Object>> getInsights(Authentication authentication) {
        UUID userId = UUID.fromString(authentication.getName());
        log.info("[SPRING_CTRL] Getting insights for userId={}", userId);

        // TODO: Implement AI insights
        return ResponseEntity.ok(ApiResponse.success(null, "Insights retrieved successfully"));
    }

    private SavingsResponseDTO mapToResponseDTO(SavingsModel savings) {
        return new SavingsResponseDTO(
                savings.getSavingsId(),
                savings.getUserId(),
                savings.getSavingsName(),
                savings.getBalance(),
                savings.getCurrency(),
                savings.getDescription(),
                savings.getTargetDate(),
                savings.getTargetAmount(),
                savings.getStatus(),
                savings.getCreatedAt(),
                savings.getUpdatedAt()
        );
    }
}