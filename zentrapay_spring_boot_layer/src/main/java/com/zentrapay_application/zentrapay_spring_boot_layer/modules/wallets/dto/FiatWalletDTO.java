package com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.dto;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.Wallet;

import java.util.UUID;

public record FiatWalletDTO(
        UUID walletId,
        String walletName,
        String currencyCode,
        String countryCode,
        String balance,
        boolean isDefault,
        String status
) {
    public static FiatWalletDTO from(Wallet wallet) {
        return new FiatWalletDTO(
                wallet.getWalletId(),
                wallet.getWalletName(),
                wallet.getCurrencyCode(),
                wallet.getCountryCode(),
                wallet.getBalance().toPlainString(),
                wallet.isDefault(),
                wallet.getStatus()
        );
    }
}
