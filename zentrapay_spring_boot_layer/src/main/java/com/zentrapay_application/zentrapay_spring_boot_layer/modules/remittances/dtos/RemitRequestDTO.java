package com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittances.dtos;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * POST /api/remittance/send body — matches the ZRemit form's flat payload
 * exactly ({@code RemittanceRepository.send} on the frontend). The recipient
 * country MUST differ from the sender's registered country: same-country
 * recipients are rejected up-front by {@code RemittancesService} because
 * domestic transfers belong to {@code POST /api/payments}.
 */
public record RemitRequestDTO(
        @NotBlank(message = "PIN is required")
        String pin,

        @NotNull(message = "Amount is required")
        @DecimalMin(value = "0.01", message = "Amount must be greater than zero")
        BigDecimal amount,

        @NotBlank(message = "Source currency code is required")
        String sourceCurrencyCode,

        /** Optional — defaults to the destination country's gateway currency. */
        String destinationCurrencyCode,

        /** Payout channel, e.g. "Mobile Money" / "Bank". Defaults to "mobile_money". */
        String channel,

        @NotBlank(message = "Recipient name is required")
        String recipientName,

        String recipientPhoneNumber,

        /** Set when the recipient is an app user (from contact search). */
        UUID recipientUserId,

        @NotBlank(message = "Recipient country code is required")
        String recipientCountryCode,

        String purpose
) {
}