package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public record UserSearchDTO(
UUID userId,
String countryCode,
String email,
String firstName,
String lastName,
String phoneNumber,
String status,
String userType,
// Comment: zentag now lives on each fiat currency account, not on the user
// (WalletsAccountsServices/FiatAccountModel) — a sender picks which of these
// to pay into. Active accounts only; empty for a brand-new user with no
// wallet yet.
List<AccountZentagDTO> fiatAccounts,
LocalDateTime updatedAt,
LocalDateTime createdAt
) {
}
