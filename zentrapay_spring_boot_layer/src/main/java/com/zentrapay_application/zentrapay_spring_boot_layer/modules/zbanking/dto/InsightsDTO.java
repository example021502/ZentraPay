package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.dto;

import java.math.BigDecimal;
import java.util.List;

public record InsightsDTO(
        BigDecimal monthlySpend,
        BigDecimal monthlyIncome,
        List<CategoryAmountDTO> topCategories
) {
}
