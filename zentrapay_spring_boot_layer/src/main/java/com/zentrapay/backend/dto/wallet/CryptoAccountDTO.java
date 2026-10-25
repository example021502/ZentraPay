package com.zentrapay.backend.dto.wallet;

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
        boolean isDefault,
        String balance,
        String status,
        LocalDateTime createdAt
) {
}
