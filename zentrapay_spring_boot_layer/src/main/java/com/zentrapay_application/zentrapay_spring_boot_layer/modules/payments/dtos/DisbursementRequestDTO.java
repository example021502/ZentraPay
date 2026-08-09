package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

/**
 * DTO for disbursement (outbound payment) requests.
 * <p>
 * {@code userId}/{@code email} are accepted for backward-compatible deserialization only —
 * the controller always overwrites both with the identity resolved from the caller's
 * validated JWT ({@code @CurrentUser}) before this DTO reaches the service/gateway layer,
 * so client-supplied values here are never trusted.
 * <pre>
 * {
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
 * and cross-border payments via Paystack (national/Ghana), Onafriq (international),
 * with Flutterwave as failover for both.
 */
public record DisbursementRequestDTO(

        UUID userId,

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