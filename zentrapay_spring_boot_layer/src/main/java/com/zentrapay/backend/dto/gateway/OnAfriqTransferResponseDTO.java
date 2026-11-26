package com.zentrapay.backend.dto.gateway;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.math.BigDecimal;

/**
 * Wire response for Paystack POST /customer.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record OnAfriqTransferResponseDTO(
        Boolean success,
        String message,
        CustomerData data
) {
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record CustomerData(
            String reference,
            @JsonProperty("tx_ref") String txRef,
            BigDecimal amount,
            String token,
            @JsonProperty("complete_message") String completeMessage
    ) {
    }
}