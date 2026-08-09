package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto;

import java.util.List;

/**
 * DTO representing the data returned by a contacts search — API_CONTRACT.md §10.
 */
public record SearchResponseDTO(
        AppUserSearchDTO senderDetails,
        List<AppUserSearchDTO> appUsers,
        List<BillProviderSearchDTO> billProviders,
        List<FundingSourceSearchDTO> fundingSources
) {
}
