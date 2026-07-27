package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.paystack;

import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Request payload for initiating a Paystack Transfer.
 * <p>
 * Maps to {@code POST /transfer}.
 *
 * @param source    Transfer source (default: "balance")
 * @param amount    Amount in the smallest currency unit (e.g., kobo for NGN, pesewas for GHS)
 * @param reference Unique transaction reference
 * @param recipient Transfer recipient code (returned from creating a transfer recipient)
 * @param reason    Narration or reason for the transfer
 * @param currency  Currency code (NGN, GHS, ZAR, USD)
 */
public record PaystackTransferRequest(
        String source,
        @JsonProperty("amount") int amount,
        @JsonProperty("reference") String reference,
        @JsonProperty("recipient") String recipient,
        @JsonProperty("reason") String reason,
        @JsonProperty("currency") String currency
) {
    /**
     * Minimal constructor for standard disbursements.
     *
     * @param amount    Amount in kobo/pesewas/cents (i.e., amount * 100)
     * @param reference Unique reference
     * @param recipient Recipient code from Paystack
     * @param reason    Narration
     * @param currency  Currency code
     */
    public PaystackTransferRequest(int amount, String reference, String recipient, String reason, String currency) {
        this("balance", amount, reference, recipient, reason, currency);
    }
}