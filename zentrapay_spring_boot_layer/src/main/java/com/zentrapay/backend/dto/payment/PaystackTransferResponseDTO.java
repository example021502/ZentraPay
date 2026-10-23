package com.zentrapay.backend.dto.payment;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Wire response for Paystack POST /transfer.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record PaystackTransferResponseDTO(
        Boolean status,
        String message,
        TransferData data
) {
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record TransferData(
            @JsonProperty("transfer_code") String transferCode,
            @JsonProperty("transfer_reference") String transferReference,
            String reference,
            Long amount,
            String currency,
            /** queued | processing | success | failed | reversed ... */
            String status,
            String reason
    ) {}
}