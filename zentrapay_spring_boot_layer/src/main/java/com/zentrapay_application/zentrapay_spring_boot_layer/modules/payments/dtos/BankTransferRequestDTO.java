package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import jakarta.validation.constraints.NotBlank;

/**
 * Flat request payload for POST /api/payments/bank-transfer — mirrors the
 * legacy frontend {@code payBankTransfer()} shape so existing clients can
 * disburse to a bank account without restructuring their payload. The
 * controller re-shapes this into a {@link PaymentRequestDTO} and delegates
 * to {@link com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.service.PaymentsService#sendMoney}.
 */
public record BankTransferRequestDTO(
        @NotBlank(message = "PIN is required")
        String pin,

        @NotBlank(message = "Amount is required")
        String amount,

        @NotBlank(message = "Currency code is required")
        String currencyCode,

        /** Bank code (nuban) or momo provider code. */
        @NotBlank(message = "Channel code is required")
        String channelCode,

        @NotBlank(message = "Account number is required")
        String accountNumber,

        @NotBlank(message = "Account name is required")
        String accountName,

        /** Optional narration. */
        String description
) {
}
