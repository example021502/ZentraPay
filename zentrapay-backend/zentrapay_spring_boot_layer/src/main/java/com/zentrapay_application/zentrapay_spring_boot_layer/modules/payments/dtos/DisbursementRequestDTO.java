package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

/**
 * DTO for disbursement (outbound payment) requests from the Node.js layer.
 * <p>
 * This DTO mirrors the exact payload structure sent by the Node.js Express layer:
 * <pre>
 * {
 *   "user_id": "uuid",
 *   "pin": "1234",
 *   "recipient": { ... },
 *   "paymentDetails": {
 *     "amount": 1000,
 *     "sourceCurrency": "NGN",
 *     "destinationCurrency": "NGN",
 *     "isInternational": false,
 *     "destinationType": "MOBILE_MONEY",
 *     "narration": "ZentraPay Disbursement Payout",
 *     "reference": "DISB-XXXXXXXX"
 *   }
 * }
 * </pre>
 * <p>
 * Designed for the African market — supports mobile money, bank transfers,
 * and cross-border payments via Paystack.
 */
public record DisbursementRequestDTO(

        @NotNull(message = "User ID is required")
        UUID userId,

        @NotNull(message = "Sender email is required")
        String email,

        @NotBlank(message = "PIN is required for authorization")
        String pin,

        @Valid
        @NotNull(message = "Recipient details are required")
        RecipientRequestDetailsDTO recipient,

        @Valid
        @NotNull(message = "Payment details are required")
        PaymentRequestDetailsDTO paymentDetails

) {
}