package com.zentrapay.backend.dto.payment;

import jakarta.validation.constraints.NotBlank;

import java.util.UUID;

/**
 * POST /api/payments/verify-account - "who owns this account?" before any money moves.
 * {@code destinationType} is BANK or MOBILE_MONEY; {@code destinationId} is the bank / network id
 * the app got from search (the code is the fallback).
 */
public record VerifyAccountRequestDTO(
        @NotBlank(message = "Destination type is required (BANK or MOBILE_MONEY)")
        String destinationType,
        UUID destinationId,
        String destinationCode,
        @NotBlank(message = "Account number is required")
        String accountNumber,
        // Country of the bank / network; defaults to the signed-in user's country
        String countryCode
) {
}
