package com.zentrapay_application.zentrapay_spring_boot_layer.modules.banks.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.banks.dtos.AccountsResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.banks.dtos.LinkNewBankRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.banks.services.BankAccountsServices;
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
@RequestMapping("/api/zbanking")
@RequiredArgsConstructor
public class banksControler {

    private final BankAccountsServices bankAccountsServices;

    @GetMapping("/accounts")
    public ResponseEntity<ApiResponse<AccountsResponseDTO>> accounts(@CurrentUser AuthenticatedUser user) {
        AccountsResponseDTO accounts = bankAccountsServices.getAccounts(user.getUserId());
        return ResponseEntity.ok(ApiResponse.success(accounts, "Bank accounts retrieved"));
    }
    @GetMapping("/userAccounts")
    public ResponseEntity<ApiResponse<AccountsResponseDTO>> userAccounts(@CurrentUser AuthenticatedUser user) {
        AccountsResponseDTO accounts = bankAccountsServices.getUserAccounts(user.getUserId());
        return ResponseEntity.ok(ApiResponse.success(accounts, "Bank accounts retrieved"));
    }

    @GetMapping("/new")
    public ResponseEntity<ApiResponse<AccountsResponseDTO>> linkBank(@CurrentUser AuthenticatedUser user, @Valid @RequestBody LinkNewBankRequestDTO request) {
        AccountsResponseDTO bank = bankAccountsServices.newBank(user.getUserId());
        return ResponseEntity.ok(ApiResponse.success(bank, "Bank linked"));
    }
}
