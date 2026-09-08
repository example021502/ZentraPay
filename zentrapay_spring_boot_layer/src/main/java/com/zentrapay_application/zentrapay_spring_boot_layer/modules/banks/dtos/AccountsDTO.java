package com.zentrapay_application.zentrapay_spring_boot_layer.modules.banks.dtos;

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
        String gateway,
        String iban,
        String currencyCode,
        Boolean payWithBank,
        String swiftBic,
        String countryCode,
        String country,
        String status,
        LocalDateTime createdAt,
        LocalDateTime updatedAt,
        String maxDailyValue,
        String maxMonthlyValue,
        String minTxnLimit,
        String maxTxnLimit,
        String maxWeeklyValue
){}
