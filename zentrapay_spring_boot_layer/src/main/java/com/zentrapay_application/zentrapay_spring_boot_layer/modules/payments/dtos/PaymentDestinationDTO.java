package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Where the money is to land — one specific currency account belonging to
 * the recipient, picked by the frontend from the searched contact's
 * {@code fiatAccounts} (search-contacts §10 / AccountZentagDTO). accountId
 * is authoritative for money movement; currencyCode is echoed back purely
 * as a display/consistency check — the account's own currency_code is what
 * PaymentsService actually moves money in.
 */
public record PaymentDestinationDTO(
        @NotNull(message = "Destination account is required")
        String accountName,

        @NotNull(message = "Destination account Identifier is required")
        String accountIdentifier,

        @NotBlank(message = "Destination currency code is required")
        String currencyCode,

        @NotBlank(message = "Destination source type is required")
        String destinationSourceType,

        @NotBlank(message = "Destination source code is required")
        String destinationSourceCode,

        @NotBlank(message = "Destination source name is required")
        String destinationSourceName



) {
}
