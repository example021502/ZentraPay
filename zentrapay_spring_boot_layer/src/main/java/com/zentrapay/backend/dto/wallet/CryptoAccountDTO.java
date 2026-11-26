package com.zentrapay.backend.dto.wallet;

import com.zentrapay.backend.service.common.Datatypes;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * A single crypto wallet entry — maps to the frontend {@code CryptoWalletSummary}
 * model. {@code balance} is a decimal {@link String}.
 */
public record CryptoAccountDTO(
        UUID id,
        String currencyCode,
        String network,
        String address,
        BigDecimal balance,
        boolean isDefault,
        Datatypes.AccountStatus status,
        LocalDateTime createdAt
) {
}
