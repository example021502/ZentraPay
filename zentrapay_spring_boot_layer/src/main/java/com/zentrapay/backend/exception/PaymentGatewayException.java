package com.zentrapay.backend.exception;

/**
 * Thrown when a payment gateway (Paystack / Flutterwave / Onafriq) or the
 * open-banking provider rejects a call or cannot be reached.
 *
 * <p>{@link #isOutcomeUnknown()} is the money-safety flag:
 * <ul>
 *   <li><b>false</b> - the gateway definitely did NOT act on the request (it was
 *       rejected, or never reached). It is safe to refund the customer and to
 *       try the next gateway.</li>
 *   <li><b>true</b> - the request may have reached the gateway (read timeout,
 *       5xx). The transfer might still go through, so the caller must NOT refund
 *       or retry on another gateway; the webhook or a status check decides.</li>
 * </ul>
 */
public class PaymentGatewayException extends RuntimeException {

    private final boolean outcomeUnknown;

    /** The gateway rejected the request (or it never reached the gateway). */
    public PaymentGatewayException(String message) {
        super(message);
        this.outcomeUnknown = false;
    }

    public PaymentGatewayException(String message, Throwable cause) {
        super(message, cause);
        this.outcomeUnknown = false;
    }

    private PaymentGatewayException(String message, Throwable cause, boolean outcomeUnknown) {
        super(message, cause);
        this.outcomeUnknown = outcomeUnknown;
    }

    /** The request may have been processed - do not refund or fail over. */
    public static PaymentGatewayException unknownOutcome(String message, Throwable cause) {
        return new PaymentGatewayException(message, cause, true);
    }

    public boolean isOutcomeUnknown() {
        return outcomeUnknown;
    }
}
