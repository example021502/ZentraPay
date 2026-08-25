package com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittances.dtos;

import java.math.BigDecimal;

/**
 * POST /api/remit/quote response — what the recipient gets and what it costs,
 * before any money moves.
 */
public record RemitQuoteResponseDTO(
        String sourceCurrencyCode,
        String destinationCurrencyCode,
        String destinationCountryCode,
        BigDecimal exchangeRate,
        BigDecimal sourceAmount,
        BigDecimal destinationAmount,
        BigDecimal fee,
        BigDecimal totalDebit
) {
}