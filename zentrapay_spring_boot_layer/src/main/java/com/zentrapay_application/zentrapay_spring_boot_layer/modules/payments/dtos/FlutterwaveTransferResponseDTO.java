package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.math.BigDecimal;

/**
 * Wire response for Flutterwave POST /transfers (failover payout execution).
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record FlutterwaveTransferResponseDTO(
        /** Flutterwave returns the string "success", not a boolean. */
        String status,
        String message,
        TransferData data
) {
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record TransferData(
            Long id,
            BigDecimal amount,
            String currency,
            /** NEW | PROCESSING | SUCCESSFUL | FAILED | REVERSED ... */
            String status,
            String reference,
            String narration,
            @JsonIgnoreProperties(ignoreUnknown = true) Object meta
    ) {}
}