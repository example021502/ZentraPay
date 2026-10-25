package com.zentrapay.backend.dto.payment;

/**
 * The account holder's name as confirmed by a payment provider.
 * {@code verified=false} means no provider offers a name lookup for this wallet (mobile money only);
 * the transfer can still go ahead because the provider registers the recipient itself.
 */
public record VerifiedAccountDTO(
        boolean verified,
        String accountName,
        String accountNumber,
        String destinationName,
        String countryCode
) {
}
