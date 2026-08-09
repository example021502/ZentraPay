package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto;

import java.util.UUID;

/**
 * DTO representing a bill provider search result — API_CONTRACT.md §10.
 */
public record BillProviderSearchDTO(
        UUID providerId,
        String billerName,
        String categoryCode,
        String logUrl,
        String userType
) {
}