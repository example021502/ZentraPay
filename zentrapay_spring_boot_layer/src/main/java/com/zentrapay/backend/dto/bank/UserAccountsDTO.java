package com.zentrapay.backend.dto.bank;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * A single crypto wallet entry — maps to the frontend {@code CryptoWalletSummary}
 * model. {@code balance} is a decimal {@link String}.
 */
public record UserAccountsDTO(
    UUID userBankId,
    UUID userId,
    BigDecimal balance,
    UUID bankId,
    String lastDigits,
    String connectionStatus,
    String connectionId,
    LocalDateTime linkedAt,
    LocalDateTime updatedAt,
    String bankName,
    String bankCode,
    String countryCode,
    String currencyCode,
    /** Display name chosen in the link sheet; falls back to {@code bankName}. */
    String linkLabel,
    /** True for the user's primary account (ZBank header). */
    Boolean primary
    ) {}
