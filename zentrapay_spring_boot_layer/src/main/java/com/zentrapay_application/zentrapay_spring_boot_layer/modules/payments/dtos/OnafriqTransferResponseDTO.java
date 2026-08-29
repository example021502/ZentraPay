package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

/**
 * Wire response for Onafriq transfer initiation (international corridor).
 * NOTE: Onafriq partner credentials are still placeholders in
 * application.properties — the exact response contract must be confirmed
 * once the partner account is provisioned; the shapes below follow the
 * common {status, message, data} envelope used by the probe endpoints.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record OnafriqTransferResponseDTO(
        boolean status,
        String message,
        TransferData data
) {
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record TransferData(
            String id,
            String reference,
            String status,
            String currency,
            Object amount
    ) {}
}