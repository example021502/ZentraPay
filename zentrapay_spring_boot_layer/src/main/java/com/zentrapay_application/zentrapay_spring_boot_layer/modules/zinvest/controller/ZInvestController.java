package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zinvest.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zinvest.model.InvestmentModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zinvest.service.ZInvestService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.Authentication;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * ZInvest Controller - Micro-investments in stocks, crypto, commodities with AI-guided portfolios
 */
@RestController
@RequestMapping("/api/zinvest")
public class ZInvestController {

    private final ZInvestService zInvestService;

    public ZInvestController(ZInvestService zInvestService) {
        this.zInvestService = zInvestService;
    }

    /**
     * Get all investments for the authenticated user.
     */
    @GetMapping("/portfolio")
    public ResponseEntity<ApiResponse<List<InvestmentModel>>> getPortfolio(Authentication authentication) {
        UUID userId = UUID.fromString(authentication.getName());
        return ResponseEntity.ok(ApiResponse.success(
                zInvestService.getUserInvestments(userId),
                "Portfolio retrieved"));
    }

    /**
     * Create a new investment.
     */
    @PostMapping("/create")
    public ResponseEntity<ApiResponse<Object>> createInvestment(
            Authentication authentication,
            @RequestParam String name,
            @RequestParam String type,
            @RequestParam String symbol,
            @RequestParam BigDecimal quantity,
            @RequestParam BigDecimal buyPrice,
            @RequestParam String currency) {
        UUID userId = UUID.fromString(authentication.getName());
        return ResponseEntity.ok(ApiResponse.success(
                zInvestService.createInvestment(userId, name, type, symbol, quantity, buyPrice, currency),
                "Investment created successfully"));
    }

    /**
     * Get investments by type.
     */
    @GetMapping("/type/{type}")
    public ResponseEntity<ApiResponse<List<InvestmentModel>>> getInvestmentsByType(
            Authentication authentication,
            @PathVariable String type) {
        UUID userId = UUID.fromString(authentication.getName());
        return ResponseEntity.ok(ApiResponse.success(
                zInvestService.getInvestmentsByType(userId, type),
                "Investments by type retrieved"));
    }

    /**
     * Get investment performance/analytics.
     */
    @GetMapping("/performance")
    public ResponseEntity<ApiResponse<Object>> getPerformance(Authentication authentication) {
        UUID userId = UUID.fromString(authentication.getName());
        // TODO: Calculate portfolio performance
        return ResponseEntity.ok(ApiResponse.success(null, "Performance metrics retrieved"));
    }

    /**
     * Sell/close an investment.
     */
    @PostMapping("/{investmentId}/sell")
    public ResponseEntity<ApiResponse<Object>> sellInvestment(
            Authentication authentication,
            @PathVariable UUID investmentId) {
        UUID userId = UUID.fromString(authentication.getName());
        return ResponseEntity.ok(ApiResponse.success(
                zInvestService.closeInvestment(userId, investmentId),
                "Investment sold successfully"));
    }

    /**
     * Liquidity Hub: portfolio value/gain-loss/risk-profile snapshot.
     */
    @GetMapping("/liquidity-profile")
    public ResponseEntity<ApiResponse<Object>> getLiquidityProfile(Authentication authentication) {
        UUID userId = UUID.fromString(authentication.getName());
        return ResponseEntity.ok(ApiResponse.success(
                zInvestService.getLiquidityProfile(userId),
                "Liquidity profile retrieved"));
    }

    /**
     * Liquidity Hub: portfolio value trend (currently a single current-value point —
     * no historical price snapshots are stored yet).
     */
    @GetMapping("/liquidity-trend")
    public ResponseEntity<ApiResponse<Object>> getLiquidityTrend(Authentication authentication) {
        UUID userId = UUID.fromString(authentication.getName());
        return ResponseEntity.ok(ApiResponse.success(
                zInvestService.getLiquidityTrend(userId),
                "Liquidity trend retrieved"));
    }

    /**
     * Liquidity Hub: concentration-risk warnings.
     */
    @GetMapping("/risks")
    public ResponseEntity<ApiResponse<Object>> getRisks(Authentication authentication) {
        UUID userId = UUID.fromString(authentication.getName());
        return ResponseEntity.ok(ApiResponse.success(
                zInvestService.getRisks(userId),
                "Risks retrieved"));
    }

    /**
     * Liquidity Hub: price-drop alerts.
     */
    @GetMapping("/alerts")
    public ResponseEntity<ApiResponse<Object>> getAlerts(Authentication authentication) {
        UUID userId = UUID.fromString(authentication.getName());
        return ResponseEntity.ok(ApiResponse.success(
                zInvestService.getAlerts(userId),
                "Alerts retrieved"));
    }
}