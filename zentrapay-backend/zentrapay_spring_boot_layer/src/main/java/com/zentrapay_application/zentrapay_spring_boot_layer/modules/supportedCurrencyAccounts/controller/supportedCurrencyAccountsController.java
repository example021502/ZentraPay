package com.zentrapay_application.zentrapay_spring_boot_layer.modules.supportedCurrencyAccounts.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.supportedCurrencyAccounts.dto.SupportedCurrenciesAccountsResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.supportedCurrencyAccounts.service.SupportedCurrenciesAccountsServices;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/supportedCurrencyAccounts")
@RequiredArgsConstructor
public class supportedCurrencyAccountsController {
    private final SupportedCurrenciesAccountsServices supportedCurrenciesAccountsServices;

    // Changed from @PostMapping to @GetMapping since fetching configuration
    // does not require mutating server state via a request body.
    @GetMapping
    public ResponseEntity<ApiResponse<SupportedCurrenciesAccountsResponseDTO>> getSupportedCurrencyAccounts() {
        System.out.println("[SPRING_CTRL] get supported currency accounts hit");
        SupportedCurrenciesAccountsResponseDTO accounts = supportedCurrenciesAccountsServices.getSupportedCurrencyAccounts();
        return ResponseEntity.ok(ApiResponse.success(accounts, "Fetch successfully"));
    }
}