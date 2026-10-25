package com.zentrapay.backend.dto.payment;

/**
 * Response of GET /api/payments/paystack/access-code: what the app needs to open a checkout.
 *
 * @param accessCode       Paystack SDK access code (null when the failover gateway was used)
 * @param reference        our reference for this top-up
 * @param authorizationUrl hosted pay page
 * @param gateway          which gateway created the checkout
 */
public record CheckoutResponseDTO(String accessCode, String reference, String authorizationUrl, String gateway) {
}
