package com.zentrapay.backend.dto.payment;

/**
 * Neutral result of "start a hosted checkout" on any gateway.
 *
 * @param checkoutUrl page the user pays on
 * @param accessCode  Paystack access code for the in-app SDK (null on other gateways)
 */
public record GatewayCheckoutResult(String checkoutUrl, String accessCode) {
}
