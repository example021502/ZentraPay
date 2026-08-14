package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto;

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
     Boolean active,
     LocalDateTime createdAt

) {
}