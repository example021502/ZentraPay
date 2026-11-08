package com.zentrapay.backend.dto.payment;

import jakarta.validation.constraints.NotBlank;

import java.math.BigDecimal;

/**
 * Retrying a payment that failed.
 */
public final class RetryDTOs {

    private RetryDTOs() {
    }

    /** POST /api/payments/retry/{transactionId} body. */
    public record RetryRequest(@NotBlank(message = "PIN is required") String pin) {
    }

    /**
     * Result of the pre-check (no PIN, nothing moves). {@code retryable=false} says why in {@code message};
     * when a party is no longer valid the failed payment keeps that reason.
     */
    public record RetryCheckDTO(boolean retryable, String message, String receiverName, BigDecimal amount,
                                String currencyCode) {
    }
}
