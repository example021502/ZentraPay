package com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.dtos;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * A single crypto wallet entry — maps to the frontend {@code CryptoWalletSummary}
 * model. {@code balance} is a decimal {@link String}.
 */
public record CryptoAccountDTO(
        UUID cryptoAccountId,
        String currencyCode,
        String network,
        String walletAddress,
        Boolean isDefault,
        String balance,
        String status,
        LocalDateTime createdAt
) {
}
