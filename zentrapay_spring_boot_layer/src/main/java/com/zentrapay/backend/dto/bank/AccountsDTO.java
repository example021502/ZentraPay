package com.zentrapay.backend.dto.bank;

import com.zentrapay.backend.service.common.Datatypes;
import jakarta.persistence.Column;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * A single crypto wallet entry — maps to the frontend {@code CryptoWalletSummary}
 * model. {@code balance} is a decimal {@link String}.
 */
public record AccountsDTO(
        UUID bankId,
        String code,
        String bankName,
        Datatypes.Gateway gateway,
        String iban,
        String currencyCode,
        Boolean payWithBank,
        String swiftBic,
        String countryCode,
        String country,
        Datatypes.AccountStatus active,
        LocalDateTime createdAt,
        LocalDateTime updatedAt,
        BigDecimal maxDailyValue,
        BigDecimal maxMonthlyValue,
        BigDecimal minTxnLimit,
        BigDecimal maxTxnLimit,
        BigDecimal maxWeeklyValue
) {
}
