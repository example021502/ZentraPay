package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto;

import java.util.UUID;

/**
 * One of a searched user's fiat currency accounts, just enough for a sender
 * to identify and pick which one to pay into — API_CONTRACT.md §10.
 */
public record AccountZentagDTO(
        UUID accountId,
        String accountName,
        String currencyCode,
        String zentag,
        boolean isDefault
) {
}
