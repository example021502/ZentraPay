package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import com.fasterxml.jackson.annotation.JsonProperty;

public record PaymentInitRequestDTO(
        String email,
        String amount,
        String currency,
        String reference,
        @JsonProperty("callback_url")
        String callbackUrl
) {
}
