package com.zentrapay_application.zentrapay_spring_boot_layer.modules.reference.dto;

import java.util.UUID;

public record CountryDTO(
        UUID countryId,
        UUID accountId,
        String countryIsoCode,
        Boolean isActive,
        Boolean isDefault
) {
}
