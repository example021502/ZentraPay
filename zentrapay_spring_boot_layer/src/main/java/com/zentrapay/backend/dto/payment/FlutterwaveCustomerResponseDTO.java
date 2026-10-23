package com.zentrapay.backend.dto.payment;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonIgnoreProperties(ignoreUnknown = true)
public record FlutterwaveCustomerResponseDTO(
        /**
         * Flutterwave returns the string "success" (not a boolean) in the
         * {@code status} field of every v3 response.
         */
        String status,
        String message,
        CustomerData data
) {
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record CustomerData(
            String id,
            String name,
            String email,
            @JsonProperty("phone_number") String phoneNumber,
            String createdAt
    ) {
    }
}