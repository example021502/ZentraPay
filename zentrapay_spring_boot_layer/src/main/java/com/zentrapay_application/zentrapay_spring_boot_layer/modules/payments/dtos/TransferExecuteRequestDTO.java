package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * POST /api/transfers/execute — outbound payout execution.
 * <p>
 * {@code recipientId} references an existing {@code transfer_recipients} row
 * (preferred); when it is absent, {@code newRecipient} must carry the full
 * destination details and a local recipient is created first. The gateway is
 * resolved by corridor (national -> PAYSTACK, international -> ONAFRIQ,
 * failover -> FLUTTERWAVE) and any gateway recipient registration happens
 * lazily per the two-tier token architecture.
 */
public record TransferExecuteRequestDTO(
        /** Existing saved recipient — optional when newRecipient is provided. */
        UUID recipientId,

        @Valid
        CreateRecipientRequestDTO newRecipient,

        @NotNull(message = "Amount is required")
        @DecimalMin(value = "0.01", message = "Amount must be positive")
        BigDecimal amount,

        @NotBlank(message = "Currency code is required")
        String currencyCode,

        /** Optional narration/reason for the transfer. */
        String reason,

        @NotBlank(message = "Transaction PIN is required")
        String pin
) {
}