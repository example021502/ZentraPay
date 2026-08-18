package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonIgnoreProperties(ignoreUnknown = true)
public record PaystackCustomerResponseDTO(
        boolean status,
        String message,
        CustomerData data
) {
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record CustomerData(
            String email,
            long integration,
            String domain,
            @JsonProperty("customer_code") String customerCode,
            long id,
            boolean identified,
            String createdAt,
            String updatedAt
    ) {}
}