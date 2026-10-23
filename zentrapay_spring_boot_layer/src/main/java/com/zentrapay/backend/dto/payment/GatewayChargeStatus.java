package com.zentrapay.backend.dto.payment;

import java.math.BigDecimal;

/**
 * What a gateway reports about a checkout when we ask it directly.
 *
 * @param successful true only when the gateway says the customer really paid
 * @param finalFailure true when the checkout is over and unpaid (failed / abandoned / expired)
 * @param amount      amount paid, in major units (null if unknown)
 * @param currency    currency paid (null if unknown)
 */
public record GatewayChargeStatus(boolean successful, boolean finalFailure, BigDecimal amount, String currency) {
}
