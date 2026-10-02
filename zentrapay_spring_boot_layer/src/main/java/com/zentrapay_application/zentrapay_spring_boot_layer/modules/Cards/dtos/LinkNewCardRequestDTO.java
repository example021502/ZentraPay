package com.zentrapay_application.zentrapay_spring_boot_layer.modules.Cards.dtos;

import jakarta.validation.constraints.NotBlank;

import java.util.UUID;

/**
 * Request body for {@code POST /api/wallets/fiat} — matches the frontend
 * {@code createFiatWallet(...)} payload {@code {walletName,currencyCode,countryCode?}}.
 */
public record LinkNewCardRequestDTO(
        @NotBlank(message = "Account name is required") String accountName,
        @NotBlank(message = "Target Bank is required") String bankName,
        UUID bankId,
        @NotBlank(message = "Target Bank code is required") String bankCode,
        @NotBlank(message = "Target account name is required") String AccountName,
        @NotBlank(message = "Target account number is required") String AccountNumber
) {
}
