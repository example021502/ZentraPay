package com.zentrapay.backend.dto.payment;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

/**
 * Wire response for Flutterwave POST /payments (hosted checkout link) —
 * the failover equivalent of Paystack's /transaction/initialize.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record FlutterwavePaymentResponseDTO(
        /** Flutterwave returns the string "success", not a boolean. */
        String status,
        String message,
        PaymentData data
) {
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record PaymentData(String link) {}
}