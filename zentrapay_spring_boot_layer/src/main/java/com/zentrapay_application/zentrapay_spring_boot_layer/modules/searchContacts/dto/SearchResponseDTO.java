package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto;


import java.util.List;

/**
 * DTO representing the data returned by a contacts search — API_CONTRACT.md §10.
 * Every list here is already scoped to the searching user's own country (see
 * SearchContactsService) — banks come from the {@code payment_channels} directory
 * synced from Paystack/Flutterwave/Onafriq, filtered to that same country.
 */
public record SearchResponseDTO(
        List<UserSearchDTO> appUsers,
        List<BillProviderSearchDTO> billProviders,
        List<FundingSourceSearchDTO> fundingSources
) {
}
