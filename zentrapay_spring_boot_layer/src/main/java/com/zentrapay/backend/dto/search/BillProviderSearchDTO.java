package com.zentrapay.backend.dto.search;

import com.zentrapay.backend.service.common.Datatypes;
import org.springframework.boot.jackson.autoconfigure.JacksonProperties;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public record BillProviderSearchDTO(
     UUID providerId,
     String billerCode,
     String billerName,
     String CategoryCode,
     String countryCode,
     List<Map<String, Object>> fetchRequirement,
     String customerParamsSchema,
     String logo,
     LocalDateTime updatedAt,
     String channelCode,
     Boolean isCrossBorderAllowed,
     Datatypes.UserType userType,
     LocalDateTime createdAt
) {
}