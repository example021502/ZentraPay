package com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.dto;

import jakarta.validation.constraints.NotBlank;

public record WalletBalancesRequestDTO(
        @NotBlank(message = "User Error") String userId
) {}