package com.zentrapay.backend.controller;

import com.zentrapay.backend.dto.common.ApiResponse;
import com.zentrapay.backend.dto.invest.InvestmentDTOs.InvestRequest;
import com.zentrapay.backend.dto.invest.InvestmentDTOs.InvestmentDTO;
import com.zentrapay.backend.security.AuthenticatedUser;
import com.zentrapay.backend.security.CurrentUser;
import com.zentrapay.backend.service.invest.InvestmentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * ZInvest (positions bought with, and sold back into, the wallet).
 * <pre>
 * GET  /api/zinvest/portfolio     my positions, newest first, each with its current price
 * POST /api/zinvest/invest        open a position (cost = quantity x buyPrice, taken from the wallet)
 * POST /api/zinvest/{id}/sell     sell a position (its value goes back into the wallet)
 * </pre>
 * The Liquidity Hub endpoints (liquidity-profile / -trend / risks / alerts) are not part of this controller.
 */
@RestController
@RequestMapping("/api/zinvest")
@RequiredArgsConstructor
public class ZInvestController {

    private final InvestmentService investmentService;

    @GetMapping("/portfolio")
    public ResponseEntity<ApiResponse<List<InvestmentDTO>>> portfolio(@CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(investmentService.portfolio(user.getUserId()), "Portfolio retrieved"));
    }

    @PostMapping("/invest")
    public ResponseEntity<ApiResponse<InvestmentDTO>> invest(@CurrentUser AuthenticatedUser user,
                                                             @Valid @RequestBody InvestRequest request) {
        return ResponseEntity.ok(ApiResponse.success(investmentService.invest(user.getUserId(), request), "Investment bought"));
    }

    @PostMapping("/{investmentId}/sell")
    public ResponseEntity<ApiResponse<InvestmentDTO>> sell(@CurrentUser AuthenticatedUser user,
                                                           @PathVariable UUID investmentId) {
        return ResponseEntity.ok(ApiResponse.success(investmentService.sell(user.getUserId(), investmentId), "Investment sold"));
    }
}
