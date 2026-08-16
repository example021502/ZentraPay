package com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.dtos;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * A single fiat wallet entry — maps to the frontend {@code FiatWallet} model.
 * {@code balance} is a decimal {@link String} so no floating-point rounding
 * ever crosses the wire (API_CONTRACT.md conventions).
 */
public record FiatAccountDTO(
        UUID accountId,
        String accountName,
        String currencyCode,
        String zentag,
        BigDecimal balance,
        boolean isDefault,
        String status,
        LocalDateTime createdAt
) {
}
