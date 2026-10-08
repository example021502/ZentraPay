package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.Datatypes;

import java.util.UUID;

public record BankSearchDTO(
        UUID bankId,
        String bankName,
        String bankCode,
        String countryCode,
        String type
) {
}