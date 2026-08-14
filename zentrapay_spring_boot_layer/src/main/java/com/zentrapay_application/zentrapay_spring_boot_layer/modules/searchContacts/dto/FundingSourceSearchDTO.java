package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;

import java.time.LocalDateTime;
import java.util.UUID;

public record FundingSourceSearchDTO(
        UUID sourceId,
        String accountIdentifier,
        String channelCode,
        String countryCode,
        Boolean is_verified,
        String sourceName,
        String sourceType,
        String accountName,
        String fundingSourceCode,
        String currency,
        String fundingType,
        Boolean isPrimary,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}