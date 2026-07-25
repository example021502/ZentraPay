package com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.dto;

import jakarta.validation.constraints.NotBlank;

import java.util.UUID;

public record CreateFiatAccountRequest(
        @NotBlank(message = "User ID is required") UUID userId,
        String currency,
        String isoCode,
        @NotBlank(message = "Account Name is required") String accountName
) {}