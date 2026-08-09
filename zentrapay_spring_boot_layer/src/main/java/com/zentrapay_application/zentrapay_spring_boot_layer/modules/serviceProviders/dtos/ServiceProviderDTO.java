package com.zentrapay_application.zentrapay_spring_boot_layer.modules.serviceProviders.dtos;

import java.math.BigDecimal;
import java.util.UUID;

public record ServiceProviderDTO(
        UUID providerId,
        String providerName,
        String categoryCode,
        String logoUrl,
        BigDecimal minAmount,
        BigDecimal maxAmount
) {
}
