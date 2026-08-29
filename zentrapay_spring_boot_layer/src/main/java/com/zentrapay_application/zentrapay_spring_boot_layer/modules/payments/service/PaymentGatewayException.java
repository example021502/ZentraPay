package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.service;

/**
 * Thrown when a payment gateway (Paystack / Onafriq / Flutterwave) rejects a
 * call or is unreachable. Business logic catches this to drive the
 * Flutterwave failover; anything left unhandled surfaces to the client as a
 * 400 via GlobalExceptionHandler with the gateway's own message.
 */
public class PaymentGatewayException extends RuntimeException {

    public PaymentGatewayException(String message) {
        super(message);
    }

    public PaymentGatewayException(String message, Throwable cause) {
        super(message, cause);
    }
}