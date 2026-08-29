package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

/** GET /transaction/initialize/:reference — used to verify a checkout. */
@JsonIgnoreProperties(ignoreUnknown = true)
public record PaystackVerifyResponseDTO(
        boolean status,
        String message,
        VerifyData data
) {
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record VerifyData(
            long id,
            String status,
            String reference,
            String gatewayResponse,
            long amount,
            String currency,
            VerifyCustomer customer,
            @JsonProperty("authorization") VerifyAuthorization authorization
    ) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record VerifyCustomer(
            long id,
            String customerCode,
            String email,
            @JsonProperty("first_name") String firstName,
            @JsonProperty("last_name") String lastName
    ) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record VerifyAuthorization(
            String authorizationCode,
            String bin,
            String last4,
            @JsonProperty("card_type") String cardType,
            String bank,
            String reusable,
            String channel
    ) {}
}