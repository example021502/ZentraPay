package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

/**
 * DTO for internal wallet-to-wallet transfers between ZentraPay app users.
 * <p>
 * Mirrors the Node.js layer's {@code /api/payments/internal} payload:
 * <pre>
 * {
 *   "userId": "uuid",
 *   "PIN": "1234",
 *   "recipient": { "phoneNumber": "+234...", "zentag": "@johndoe" },
 *   "paymentDetails": { "amount": 5000, "currencyCode": "NGN" }
 * }
 * </pre>
 */
public record WalletToWalletRequestDTO(

        @NotNull(message = "User ID is required")
        UUID userId,

        @NotBlank(message = "PIN is required for authorization")
        String PIN,

        @Valid
        @NotNull(message = "Recipient details are required")
        InternalRecipientRequestDTO recipient,

        @Valid
        @NotNull(message = "Payment details are required")
        InternalPaymentDetailsDTO paymentDetails

) {
}