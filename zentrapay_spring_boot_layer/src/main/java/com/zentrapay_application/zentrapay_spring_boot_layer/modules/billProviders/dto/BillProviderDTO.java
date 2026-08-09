package com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.dto;

import java.util.UUID;

public record BillProviderDTO(
        UUID providerId,
        String billerName,
        String categoryCode,
        String logoUrl,
        String fetchRequirement
) {
}
