package com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record CreateFiatAccountRequest(
        @NotBlank(message = "User ID is required") String userId,
        String currency,
        String isoCode,
        @NotBlank(message = "Account Name is required") String accountName
) {}