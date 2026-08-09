package com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.dto;

import jakarta.validation.constraints.NotBlank;

public record CreateFiatWalletRequestDTO(
        @NotBlank(message = "Wallet name is required") String walletName,
        @NotBlank(message = "Currency code is required") String currencyCode,
        String countryCode
) {
}
