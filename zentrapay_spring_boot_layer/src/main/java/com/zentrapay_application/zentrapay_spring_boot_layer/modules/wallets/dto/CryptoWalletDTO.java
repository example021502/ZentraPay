package com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.dto;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.CryptoWallet;

import java.util.UUID;

public record CryptoWalletDTO(
        UUID cryptoWalletId,
        String currencyCode,
        String network,
        String walletAddress,
        String balance,
        String status
) {
    public static CryptoWalletDTO from(CryptoWallet wallet) {
        return new CryptoWalletDTO(
                wallet.getCryptoWalletId(),
                wallet.getCurrencyCode(),
                wallet.getNetwork(),
                wallet.getWalletAddress(),
                wallet.getBalance().toPlainString(),
                wallet.getStatus()
        );
    }
}
