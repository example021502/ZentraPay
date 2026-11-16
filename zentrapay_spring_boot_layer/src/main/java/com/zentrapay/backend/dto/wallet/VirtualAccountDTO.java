package com.zentrapay.backend.dto.wallet;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * A single fiat wallet entry — maps to the frontend {@code FiatWallet} model.
 * {@code balance} is a decimal {@link String} so no floating-point rounding
 * ever crosses the wire (API_CONTRACT.md conventions).
 */
public record VirtualAccountDTO(
        UUID id,
        String merchantReference,
        String currency,
        String status,
        String accountNumber,
        String accountType,
        BigDecimal balance,
        boolean isActive,
        boolean isDefault,
        LocalDateTime createdAt
) {
}
