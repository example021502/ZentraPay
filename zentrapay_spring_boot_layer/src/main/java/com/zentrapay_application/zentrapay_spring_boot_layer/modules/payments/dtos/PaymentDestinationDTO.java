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
        @NotNull(message = "destination.accountId is required")
        UUID accountId,

        @NotBlank(message = "destination.currencyCode is required")
        String currencyCode,

        @NotNull(message = "destination.amount is required")
        @DecimalMin(value = "0.01", message = "destination.amount must be positive")
        BigDecimal amount
) {
}
