package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Wire response for Paystack POST /transferrecipient.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record PaystackRecipientResponseDTO(
        boolean status,
        String message,
        RecipientData data
) {
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record RecipientData(
            /** e.g. "RCP_1a2b3c4d5e" — persisted into recipient_gateway_tokens. */
            @JsonProperty("recipient_code") String recipientCode,
            String type,
            String name,
            String currency
    ) {}
}