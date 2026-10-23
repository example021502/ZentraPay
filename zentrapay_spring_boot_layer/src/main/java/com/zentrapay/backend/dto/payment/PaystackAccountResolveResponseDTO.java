package com.zentrapay.backend.dto.payment;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Wire response for Paystack GET /bank/resolve.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record PaystackAccountResolveResponseDTO(
        Boolean status,
        String message,
        ResolveData data
) {
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record ResolveData(
            @JsonProperty("account_number") String accountNumber,
            @JsonProperty("account_name") String accountName
    ) {}
}
