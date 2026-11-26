package com.zentrapay.backend.controller;

import com.zentrapay.backend.dto.common.ApiResponse;
import com.zentrapay.backend.dto.wallet.*;
import com.zentrapay.backend.service.DigitalAccounts.AccountsServices;
import com.zentrapay.backend.security.AuthenticatedUser;
import com.zentrapay.backend.security.CurrentUser;
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
@RequestMapping("/api/accounts")
@RequiredArgsConstructor
public class DigitalAccountController {

    private final AccountsServices accountsServices;

    @GetMapping("/balances")
    public ResponseEntity<ApiResponse<AccountsBalancesResponseDTO>> getAccountsBalances(@CurrentUser AuthenticatedUser user) {
        AccountsBalancesResponseDTO balances = accountsServices.getAccounts(user.getUserId());
        return ResponseEntity.ok(ApiResponse.success(balances, "Accounts retrieved"));
    }

    @PostMapping("/new/fiat")
    public ResponseEntity<ApiResponse<FiatDigitalAccountDTO>> createFiatWallet(
            @CurrentUser AuthenticatedUser user,
            @Valid @RequestBody CreateFiatAccountRequest request) {
        FiatDigitalAccountDTO account = accountsServices.createFiatAccount(
                user.getUserId(),
                request);
        return ResponseEntity.ok(ApiResponse.success(account, "Account created!"));
    }

    @PostMapping("/supportedCurrencies")
    public ResponseEntity<ApiResponse<List<SupportedCurrencyDTO>>> getSupportedCurrencies(
            @CurrentUser AuthenticatedUser user
    ) {
        List<SupportedCurrencyDTO> currencies = accountsServices.getSupportedCurrencies(user.getUserId());
        return ResponseEntity.ok(ApiResponse.success(currencies, "Supported currencies retrieved"));
    }
}
