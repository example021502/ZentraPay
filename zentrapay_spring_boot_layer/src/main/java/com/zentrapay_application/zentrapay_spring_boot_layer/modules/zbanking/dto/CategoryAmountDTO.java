package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.dto;

import java.math.BigDecimal;

public record CategoryAmountDTO(
        String categoryCode,
        BigDecimal amount
) {
}
