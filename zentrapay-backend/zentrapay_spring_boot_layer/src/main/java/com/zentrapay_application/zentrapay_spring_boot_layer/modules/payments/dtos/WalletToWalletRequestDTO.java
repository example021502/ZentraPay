package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import jakarta.validation.constraints.NotBlank;

import java.math.BigDecimal;
import java.util.UUID;

public record WalletToWalletRequestDTO(
        @NotBlank(message = "User Error") UUID userId,
        @NotBlank(message = "Amount missing") BigDecimal amount,
        @NotBlank(message = "PIN missing") String PIN,
        String phoneNumber,
        String zentag,
        String currencyCode
) {
}
