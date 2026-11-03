package com.zentrapay.backend.dto.payment;

import java.util.UUID;

/**
 * The account holder's name as confirmed by a payment provider.
 * {@code verified=false} means no provider offers a name lookup for this wallet (mobile money only);
 * the transfer can still go ahead because the provider registers the recipient itself.
 *
 * <p>{@code accountNumber} is MASKED (last 4 digits only). {@code verificationToken} is the only thing
 * the app needs to send with the payment: it is encrypted, bound to the user, and expires after 15 minutes.
 */
public record VerifiedAccountDTO(
        boolean verified,
        UUID gatewayId,
        String accountName,
        String accountNumber,
        String destinationName,
        String countryCode,
        String verificationToken
) {
}
