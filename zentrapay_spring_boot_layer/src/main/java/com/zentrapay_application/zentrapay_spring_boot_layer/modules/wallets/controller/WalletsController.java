package com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.Currency;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.dto.CreateCryptoWalletRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.dto.CreateFiatWalletRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.dto.FiatWalletDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.dto.WalletsResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.service.WalletsService;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.AuthenticatedUser;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.CurrentUser;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * API contract §3 — supersedes {@code /api/accounts/*} and
 * {@code /api/currencyBalances/*}.
 */
@RestController
@RequestMapping("/api/wallets")
@RequiredArgsConstructor
public class WalletsController {

    private final WalletsService walletsService;

    @GetMapping
    public ResponseEntity<ApiResponse<WalletsResponseDTO>> getWallets(@CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(walletsService.getUserWallets(user.userId()), "Wallets retrieved"));
    }

    @PostMapping("/fiat")
    public ResponseEntity<ApiResponse<FiatWalletDTO>> createFiatWallet(@CurrentUser AuthenticatedUser user,
                                                                       @RequestBody @Valid CreateFiatWalletRequestDTO request) {
        FiatWalletDTO wallet = walletsService.createFiatWallet(user.userId(), request);
        return ResponseEntity.ok(ApiResponse.success(wallet, "Fiat wallet created"));
    }

    /**
     * Crypto wallet logic is explicitly deferred (API contract §3) — balance/transfer
     * behavior for crypto wallets ships in a later pass. Rather than guess at that
     * business logic, this returns 501 as the contract specifies.
     */
    @PostMapping("/crypto")
    public ResponseEntity<ApiResponse<Object>> createCryptoWallet(@CurrentUser AuthenticatedUser user,
                                                                  @RequestBody @Valid CreateCryptoWalletRequestDTO request) {
        return ResponseEntity.status(HttpStatus.NOT_IMPLEMENTED)
                .body(ApiResponse.error("Crypto wallets are not yet supported"));
    }

    /**
     * Crypto wallet logic is explicitly deferred (API contract §3) — balance/transfer
     * behavior for crypto wallets ships in a later pass. Rather than guess at that
     * business logic, this returns 501 as the contract specifies.
     */

    @PostMapping("/supportedCurrencies")
    public ResponseEntity<ApiResponse<List<Currency>>> getSupportedCurrencies() {
        List<Currency> supportedCurrencies = walletsService.getAllSupportedCurrencies();
        return ResponseEntity.ok(ApiResponse.success(supportedCurrencies, "Fetch successful"));
    }
}
