package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Wire response for Paystack POST /customer.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record PaystackCustomerResponseDTO(
        boolean status,
        String message,
        CustomerData data
) {
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record CustomerData(
            long id,
            @JsonProperty("customer_code") String customerCode,
            String email,
            @JsonProperty("first_name") String firstName,
            @JsonProperty("last_name") String lastName
    ) {}
}