package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto;

import java.util.UUID;

public record BankSearchDTO(
        UUID bankId,
        String bankName,
        String bankCode,
        String countryCode
) {
}