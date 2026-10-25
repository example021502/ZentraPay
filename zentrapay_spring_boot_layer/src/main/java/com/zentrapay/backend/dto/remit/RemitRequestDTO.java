package com.zentrapay.backend.dto.remit;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * POST /api/remittance/send body. The recipient country MUST differ from the sender's registered
 * country: same-country recipients are rejected up-front by {@code RemittancesService} because
 * domestic transfers belong to {@code POST /api/payments/initialize}.
 *
 * <p>Three kinds of recipient ({@code recipientType}):
 * <ul>
 *   <li>USER         - a ZentraPay user ({@code recipientUserId}); wallet to wallet.</li>
 *   <li>BANK         - a bank account abroad ({@code bankId}/{@code bankCode}, {@code accountNumber}).</li>
 *   <li>MOBILE_MONEY - a mobile-money wallet abroad ({@code mobileMoneyProviderId}/{@code mobileMoneyProviderCode},
 *       {@code recipientPhoneNumber}).</li>
 * </ul>
 * Bank and mobile-money sends are checked with the payment providers before any money is debited.
 */
public record RemitRequestDTO(
        @NotBlank(message = "PIN is required")
        String pin,

        @NotNull(message = "Amount is required")
        @DecimalMin(value = "0.01", message = "Amount must be greater than zero")
        BigDecimal amount,

        @NotBlank(message = "Source currency code is required")
        String sourceCurrencyCode,

        /** Optional - defaults to the destination country's gateway currency. */
        String destinationCurrencyCode,

        /** Payout channel, e.g. "Mobile Money" / "Bank". Defaults from the recipient type. */
        String channel,

        @NotBlank(message = "Recipient name is required")
        String recipientName,

        String recipientPhoneNumber,

        /** Set when the recipient is an app user (from contact search). */
        UUID recipientUserId,

        @NotBlank(message = "Recipient country code is required")
        String recipientCountryCode,

        String purpose,

        /** USER (default when recipientUserId is set), BANK or MOBILE_MONEY. */
        String recipientType,

        UUID bankId,
        String bankCode,
        String accountNumber,

        UUID mobileMoneyProviderId,
        String mobileMoneyProviderCode
) {
}
