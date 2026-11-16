package com.zentrapay.backend.dto.gateway;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Wire response for Paystack POST /customer.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record FincraNewAccountResponse(
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
            String bankName
    ) {
    }

    public record KYCInformation(
            String firstName,
            String lastName,
            String email
    ) {
    }


}