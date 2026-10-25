package com.zentrapay.backend.dto.search;

import com.zentrapay.backend.service.common.Datatypes;

import java.util.UUID;

public record BankSearchDTO(
        UUID bankId,
        String bankName,
        String bankCode,
        String countryCode,
        String type
) {
}