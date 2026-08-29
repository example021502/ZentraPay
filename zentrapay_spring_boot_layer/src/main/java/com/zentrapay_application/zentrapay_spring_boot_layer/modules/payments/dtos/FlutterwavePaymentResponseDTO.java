package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

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