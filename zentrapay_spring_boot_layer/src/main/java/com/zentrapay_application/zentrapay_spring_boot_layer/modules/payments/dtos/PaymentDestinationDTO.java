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
//destination account identifier
        @NotNull(message = "Destination account Identifier is required")
        String accountIdentifier,
//destination account name
        @NotBlank(message = "Account name is required")
        String accountName,
//      destination currency code
        @NotBlank(message = "Destination currency code is required")
        String currencyCode,
//      destination country code
        @NotBlank(message = "Destination country is required")
        String countryCode,
//       payout channel Bank/mobile money
        @NotBlank(message = "Destination channel code is required")
        String checkoutType,
//      destination source code bank code, mobile money provider code, zentrapay_app
        @NotBlank(message = "Destination source code is required")
        String channelCode

) {
}
