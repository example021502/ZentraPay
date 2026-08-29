package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Wire response for Paystack POST /transfer.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record PaystackTransferResponseDTO(
        boolean status,
        String message,
        TransferData data
) {
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record TransferData(
            @JsonProperty("transfer_code") String transferCode,
            @JsonProperty("transfer_reference") String transferReference,
            String reference,
            long amount,
            String currency,
            /** queued | processing | success | failed | reversed ... */
            String status,
            String reason
    ) {}
}