package com.zentrapay.backend.dto.gateway;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.math.BigDecimal;

/**
 * Wire response for Paystack POST /customer.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record PaystackValidateBillAccountResponseDTO(
        Boolean success,
        String message,
        CustomerData data
) {
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record CustomerData(
            String accountNumber,
            String accountName
    ) {
    }
}