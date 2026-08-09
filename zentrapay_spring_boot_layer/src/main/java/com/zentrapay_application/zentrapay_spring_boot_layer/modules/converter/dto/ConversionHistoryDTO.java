package com.zentrapay_application.zentrapay_spring_boot_layer.modules.converter.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record ConversionHistoryDTO(
        String fromCurrency,
        String toCurrency,
        BigDecimal amount,
        BigDecimal convertedAmount,
        LocalDateTime createdAt
) {
}
