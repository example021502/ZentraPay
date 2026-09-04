package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Wire response for Paystack GET /bank/resolve.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record PaystackAccountResolveResponseDTO(
        boolean status,
        String message,
        ResolveData data
) {
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record ResolveData(
            @JsonProperty("account_number") String accountNumber,
            @JsonProperty("account_name") String accountName
    ) {}
}
