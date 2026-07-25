package com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.dto;

import jakarta.validation.constraints.NotBlank;

public record CreateCryptoAccountRequest(
        @NotBlank(message = "User ID is required") String userId,
        @NotBlank(message = "Currency code is required") String currencyCode,
        @NotBlank(message = "Currency name is required") String currencyName,
        @NotBlank(message = "Network is required") String network,
        @NotBlank(message = "Wallet address is required") String walletAddress
) {}