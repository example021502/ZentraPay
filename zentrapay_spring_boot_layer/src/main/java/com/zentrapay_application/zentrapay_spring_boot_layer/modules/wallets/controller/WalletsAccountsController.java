package com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.dtos.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.services.WalletsAccountsServices;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.AuthenticatedUser;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.CurrentUser;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Wallets & Balances - API_CONTRACT.md se3.
 * GET  /api/wallets                     -> fiat + crypto wallets for the user
 * POST /api/wallets/fiat                -> create a fiat wallet
 * POST /api/wallets/supportedCurrencies -> supported currencies (frontend contract)
 */
@RestController
@RequestMapping("/api/wallet")
@RequiredArgsConstructor
public class WalletsAccountsController {

    private final WalletsAccountsServices walletsServices;

    @GetMapping("/balances")
    public ResponseEntity<ApiResponse<AccountsBalancesResponseDTO>> getUserWallets(@CurrentUser AuthenticatedUser user) {
        AccountsBalancesResponseDTO balances = walletsServices.getUserBalances(user.getUserId());
        return ResponseEntity.ok(ApiResponse.success(balances, "Wallets retrieved"));
    }

    @PostMapping("/newFiat")
    public ResponseEntity<ApiResponse<FiatAccountDTO>> createFiatWallet(
            @CurrentUser AuthenticatedUser user,
            @Valid @RequestBody CreateFiatAccountRequest request) {
        FiatAccountDTO account = walletsServices.createFiatAccount(user.getUserId(), request);
        return ResponseEntity.ok(ApiResponse.success(account, "Account created!"));
    }

    @PostMapping("/supportedCurrencies")
    public ResponseEntity<ApiResponse<List<SupportedCurrencyDTO>>> getSupportedCurrencies(
            @CurrentUser AuthenticatedUser user
    ) {
        List<SupportedCurrencyDTO> currencies = walletsServices.getSupportedCurrencies(user.getUserId());
        return ResponseEntity.ok(ApiResponse.success(currencies, "Supported currencies retrieved"));
    }
}
