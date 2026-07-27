package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dto;

import java.math.BigDecimal;
import java.util.Map;

/**
 * Request DTO for processing payments through the gateway system.
 * This encapsulates all required information for a payment transaction.
 */
public record PaymentRequest(
        BigDecimal amount,
        String currency,
        String transactionType, // DEPOSIT, WITHDRAWAL, CREDIT, DEBIT, CRYPTO_PURCHASE
        String customerEmail,
        String customerPhone,
        String description,
        String reference,
        String country, // Ghana, Nigeria, International, etc.
        String gatewayType, // PAYSTACK, FLUTTERWAVE, ONAFRIQ (optional - auto-selected if null)
        Map<String, Object> metadata // Additional transaction metadata
) {
}