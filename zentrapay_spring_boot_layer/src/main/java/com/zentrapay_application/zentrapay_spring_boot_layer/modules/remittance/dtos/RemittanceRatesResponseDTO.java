package com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittance.dtos;

import java.math.BigDecimal;

public record RemittanceRatesResponseDTO(
        BigDecimal exchangeRate,
        BigDecimal fee
) {
}
