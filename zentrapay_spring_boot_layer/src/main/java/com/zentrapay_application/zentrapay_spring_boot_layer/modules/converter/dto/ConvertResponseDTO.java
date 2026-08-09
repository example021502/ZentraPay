package com.zentrapay_application.zentrapay_spring_boot_layer.modules.converter.dto;

import java.math.BigDecimal;

public record ConvertResponseDTO(
        BigDecimal convertedAmount,
        BigDecimal rate
) {
}
