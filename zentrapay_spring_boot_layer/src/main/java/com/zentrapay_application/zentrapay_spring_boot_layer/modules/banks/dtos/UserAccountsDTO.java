package com.zentrapay_application.zentrapay_spring_boot_layer.modules.banks.dtos;

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
    String currencyCode
    ) {}
