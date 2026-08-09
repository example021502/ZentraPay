package com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * Crypto wallet creation is explicitly deferred (API contract §3) — this DTO
 * exists so the endpoint shape matches the contract even though the handler
 * currently just returns HTTP 501.
 */
public record CreateCryptoWalletRequestDTO(
        @NotBlank(message = "Currency code is required") String currencyCode,
        String network,
        @NotBlank(message = "Wallet address is required") String walletAddress
) {
}
