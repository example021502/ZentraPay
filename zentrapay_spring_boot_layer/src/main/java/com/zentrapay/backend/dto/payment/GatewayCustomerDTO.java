package com.zentrapay.backend.dto.payment;

import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * A gateway customer as the app reads it (keys match the app's customer response models).
 */
public record GatewayCustomerDTO(
        Integer id,
        String code,
        String email,
        @JsonProperty("first_name") String firstName,
        @JsonProperty("last_name") String lastName,
        String phone
) {
}
