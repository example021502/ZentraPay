package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

/**
 * {@code GET /api/payments/paystack/access-code} response (API contract §6).
 */
public record PaystackAccessCodeResponseDTO(
        String accessCode,
        String reference,
        String authorizationUrl
) {
}
