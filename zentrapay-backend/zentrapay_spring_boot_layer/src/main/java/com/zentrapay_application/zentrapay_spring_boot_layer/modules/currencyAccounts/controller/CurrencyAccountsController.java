package com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.dto.CreateFiatAccountRequest;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.dto.CreateCryptoAccountRequest;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.dto.CryptoAccountResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.dto.FiatAccountResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.service.CurrencyAccountsService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/accounts")
@RequiredArgsConstructor
public class CurrencyAccountsController {
    private final CurrencyAccountsService currencyAccountsService;

    @PostMapping("/newAccount/fiat")
    public ResponseEntity<ApiResponse<FiatAccountResponse>> createFiatAccount(@RequestBody @Valid CreateFiatAccountRequest request) {
        System.out.println("[SPRING_CTRL] create fiat account hit by " + request);
        FiatAccountResponse account = currencyAccountsService.createFiatAccount(request);
        return ResponseEntity.ok(ApiResponse.success(account, "Fiat account created successfully"));
    }

    @PostMapping("/newAccount/crypto")
    public ResponseEntity<ApiResponse<CryptoAccountResponse>> createCryptoAccount(@RequestBody @Valid CreateCryptoAccountRequest request) {
        System.out.println("[SPRING_CTRL] create crypto account hit by " + request);
        CryptoAccountResponse account = currencyAccountsService.createCryptoAccount(request);
        return ResponseEntity.ok(ApiResponse.success(account, "Crypto account created successfully"));
    }
}