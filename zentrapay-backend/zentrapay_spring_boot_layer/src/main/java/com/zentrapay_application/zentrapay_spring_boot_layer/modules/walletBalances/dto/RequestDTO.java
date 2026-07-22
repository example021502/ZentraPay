package com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.dto;

import jakarta.validation.constraints.NotBlank;

<<<<<<< HEAD
public record RequestDTO(
=======
public record WalletBalancesRequestDTO(
>>>>>>> update
        @NotBlank(message = "User Error") String userId
) {}