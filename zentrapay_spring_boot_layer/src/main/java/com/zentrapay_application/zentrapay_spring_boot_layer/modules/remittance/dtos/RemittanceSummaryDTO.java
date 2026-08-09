package com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittance.dtos;

import java.math.BigDecimal;
import java.util.UUID;

public record RemittanceSummaryDTO(
        UUID remittanceId,
        String status,
        BigDecimal exchangeRate,
        BigDecimal fee
) {
}
