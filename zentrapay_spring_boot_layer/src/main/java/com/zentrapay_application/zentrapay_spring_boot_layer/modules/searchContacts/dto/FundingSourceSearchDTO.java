package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto;

import java.util.UUID;

public record FundingSourceSearchDTO(
        UUID sourceId,
        String sourceName,
        String accountIdentifier,
        Boolean isVerified,
        String userType
) {
}
