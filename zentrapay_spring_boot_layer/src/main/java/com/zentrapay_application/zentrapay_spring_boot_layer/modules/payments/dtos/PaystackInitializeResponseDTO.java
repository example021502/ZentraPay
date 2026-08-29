package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Wire response for Paystack POST /transaction/initialize.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record PaystackInitializeResponseDTO(
        boolean status,
        String message,
        InitData data
) {
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record InitData(
            @JsonProperty("authorization_url") String authorizationUrl,
            @JsonProperty("access_code") String accessCode,
            String reference
    ) {}
}