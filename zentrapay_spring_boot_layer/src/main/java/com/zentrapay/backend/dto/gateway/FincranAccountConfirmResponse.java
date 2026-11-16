package com.zentrapay.backend.dto.gateway;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

/**
 * Wire response for Paystack POST /customer.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record FincranAccountConfirmResponse(
        Boolean success,
        String message,
        CustomerData data
) {
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record CustomerData(
            String status,
            Boolean isActive,
            String currency,
            String accountType,
            String merchantReference,
            AccountInformation accountInformation,
            KYCInformation kycInformation
    ) {
    }

    public record AccountInformation(
            String accountNumber,
            String accountName,
            String bankName,
            String bankCode
    ) {
    }

    public record KYCInformation(
            String firstName,
            String lastName,
            String email
    ) {
    }


}