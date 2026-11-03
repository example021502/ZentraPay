package com.zentrapay.backend.dto.payment;

/**
 * The reusable card a gateway reports after a successful card payment: its token plus the display
 * details printed on a receipt. Never contains the card number or CVV.
 *
 * @param gateway   PAYSTACK or FLUTTERWAVE (a token only works on the gateway that issued it)
 * @param token     authorization_code (Paystack) / card token (Flutterwave)
 * @param signature the gateway's fingerprint of the card (falls back to last4+expiry when it gives none)
 * @param reusable  false when the gateway says this card cannot be charged again
 */
public record GatewayCardToken(String gateway, String token, String signature, String last4, String brand,
                               String cardType, String bank, Integer expMonth, Integer expYear,
                               String countryCode, boolean reusable) {
}
