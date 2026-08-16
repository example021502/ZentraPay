package com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.dtos;

import jakarta.validation.constraints.NotBlank;

/**
 * Request body for {@code POST /api/wallets/fiat} — matches the frontend
 * {@code createFiatWallet(...)} payload {@code {walletName,currencyCode,countryCode?}}.
 */
public record CreateFiatAccountRequest(
        @NotBlank(message = "Account name is required") String accountName,
        @NotBlank(message = "Currency code is required") String currencyCode,
        String countryCode
) {
}
