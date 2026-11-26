package com.zentrapay.backend.dto.wallet;

import com.zentrapay.backend.service.common.Datatypes;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * A single fiat wallet entry — maps to the frontend {@code FiatWallet} model.
 * {@code balance} is a decimal {@link String} so no floating-point rounding
 * ever crosses the wire (API_CONTRACT.md conventions).
 */
public record FiatDigitalAccountDTO(
        UUID id,
        String zentag,
        String currency,
        String status,
        String phoneNumber,
        String label,
        BigDecimal balance,
        Datatypes.AccountStatus isActive,
        boolean isDefault,
        LocalDateTime createdAt
) {
}
