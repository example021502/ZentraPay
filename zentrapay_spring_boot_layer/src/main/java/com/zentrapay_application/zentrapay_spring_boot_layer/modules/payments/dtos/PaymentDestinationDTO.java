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
        @NotBlank(message = "Destination Country missing") String countryCode,
        @NotBlank(message = "Destination Currency missing") String currencyCode,
        @NotBlank(message = "Destination Account Identifier missing") String accountIdentifier,
        @NotBlank(message = "Destination Source Type missing") String sourceType,
        @NotBlank(message = "Destination Source Name missing") String sourceName,
        @NotBlank(message = "Destination Source Identifier missing") String sourceIdentifier
) {
}
