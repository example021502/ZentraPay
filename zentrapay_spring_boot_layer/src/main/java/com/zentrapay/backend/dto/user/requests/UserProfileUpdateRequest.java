package com.zentrapay.backend.dto.user.requests;


import com.zentrapay.backend.service.common.Datatypes;

import java.time.LocalDate;

public record UserProfileUpdateRequest(
        String firstName,
        String lastName,
        String email,
        String phoneNumber,
        String countryCode,
        LocalDate dateOfBirth,
        String nationalityCountryCode,
        Datatypes.KYCDocumentType documentType,
        String documentNumber,
        String documentIssuingCountryCode,
        LocalDate documentExpirationDate,
        String addressLine1,
        String addressLine2,
        String cityName,
        String stateOrRegion,
        String postalCode,
        String occupationTitle
) {
    public UserProfileUpdateRequest {
        if (!phoneNumber().isBlank() && countryCode().isBlank()) {
            throw new RuntimeException("Phone number country code missing");
        }
    }
}
