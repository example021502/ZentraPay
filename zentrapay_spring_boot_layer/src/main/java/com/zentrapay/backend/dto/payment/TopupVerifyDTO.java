package com.zentrapay.backend.dto.payment;

import java.math.BigDecimal;

/**
 * GET /api/topup/verify/{reference}: where a top-up stands after the customer paid (or closed the checkout).
 * {@code status} is SUCCESS, PENDING or FAILED.
 */
public record TopupVerifyDTO(String reference, String status, BigDecimal amount, String currency, String message) {
}
