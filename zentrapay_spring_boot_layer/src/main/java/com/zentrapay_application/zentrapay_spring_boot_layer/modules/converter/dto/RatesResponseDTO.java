package com.zentrapay_application.zentrapay_spring_boot_layer.modules.converter.dto;

import java.math.BigDecimal;
import java.util.Map;

public record RatesResponseDTO(
        String base,
        Map<String, BigDecimal> rates
) {
}
