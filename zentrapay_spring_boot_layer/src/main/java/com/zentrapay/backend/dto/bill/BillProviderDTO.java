package com.zentrapay.backend.dto.bill;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public record BillProviderDTO(
        UUID providerId,
        String billerCode,
        String billerName,
        String categoryCode,
        String countryCode,
        String logoUrl,
        LocalDateTime createdAt,
        LocalDateTime updatedAt,
        String channelCode,
        Boolean isCrossBorderAllowed,
        Boolean active,
        List<Map<String, Object>> fetchRequirement
) {
}
