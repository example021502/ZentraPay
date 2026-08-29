package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import jakarta.validation.constraints.NotBlank;

/**
 * Gateway-agnostic creation of a payout destination (tier 1:
 * {@code transfer_recipients}). Works for both traditional bank accounts
 * (destinationType BANK) and mobile-money wallets (MOBILE_MONEY).
 * <p>
 * Also used inline by the bank branch of POST /api/payments, where the
 * frontend supplies the bank details in the destination block.
 */
public record CreateRecipientRequestDTO(
        /** BANK | MOBILE_MONEY (case-insensitive). */
        @NotBlank(message = "Destination type is required (BANK or MOBILE_MONEY)")
        String destinationType,

        @NotBlank(message = "Recipient name is required")
        String recipientName,

        /** Bank account number (nuban) or wallet MSISDN. */
        @NotBlank(message = "Account number is required")
        String accountIdentifier,

        /** Bank code or momo provider code (e.g. MTN, VOD, ATL). */
        @NotBlank(message = "Provider code is required")
        String providerCode,

        @NotBlank(message = "Provider name is required")
        String providerName,

        @NotBlank(message = "Country code is required")
        String countryCode,

        @NotBlank(message = "Currency code is required")
        String currencyCode
) {
}