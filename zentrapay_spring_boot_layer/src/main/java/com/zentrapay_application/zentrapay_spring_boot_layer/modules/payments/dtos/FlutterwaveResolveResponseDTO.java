package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

/**
 * Wire response for Flutterwave POST /accounts/resolve.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record FlutterwaveResolveResponseDTO(
        /** Flutterwave returns the string "success", not a boolean. */
        String status,
        String message,
        ResolveData data
) {
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record ResolveData(
            String account_number,
            String account_name
    ) {}
}
