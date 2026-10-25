package com.zentrapay.backend.dto.payment;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

/**
 * Wire response for Flutterwave POST /beneficiaries.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record FlutterwaveBeneficiaryResponseDTO(
        /** Flutterwave returns the string "success", not a boolean. */
        String status,
        String message,
        BeneficiaryData data
) {
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record BeneficiaryData(String id) {
    }
}
