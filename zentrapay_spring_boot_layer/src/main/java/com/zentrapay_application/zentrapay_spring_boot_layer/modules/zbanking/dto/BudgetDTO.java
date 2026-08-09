package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.dto;

import java.math.BigDecimal;

public record BudgetDTO(
        BigDecimal monthlyLimit,
        BigDecimal spentThisMonth,
        BigDecimal remaining
) {
}
