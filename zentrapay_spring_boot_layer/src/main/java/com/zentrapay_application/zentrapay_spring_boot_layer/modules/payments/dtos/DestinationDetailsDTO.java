package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import jakarta.validation.constraints.NotBlank;

/**
 * ({@code country} distinguishes the two; both stay inside the ledger, no gateway
 * involved). Other destination types (bank account, mobile money, bill provider)
 * already have their own endpoints and request shapes better suited to them; this
 * field exists so the frontend has one consistent envelope to fill in, and so
 * validating/rejecting an unsupported destination here gives a clear error instead
 * of silently misrouting money.
 */
public record DestinationDetailsDTO(
        @NotBlank(message = "Destination type is required")
        String destinationType,

        String accountNumber,

        String accountName,

        String network,

        String country,

        String identifier
) {
}
