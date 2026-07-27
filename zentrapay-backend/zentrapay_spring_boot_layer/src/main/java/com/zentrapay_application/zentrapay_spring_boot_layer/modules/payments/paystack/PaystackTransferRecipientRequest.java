package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.paystack;

import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Request payload for creating a Paystack Transfer Recipient.
 * <p>
 * Paystack requires a transfer recipient to be created before initiating a transfer.
 * This maps to {@code POST /transferrecipient}.
 *
 * @param type          Recipient type (e.g., "nuban", "mobile_money", "basa", "ghipss")
 * @param name          Recipient account name
 * @param accountNumber Recipient account number or mobile money number
 * @param bankCode      Bank code or mobile money provider code
 * @param currency      Currency code (NGN, GHS, ZAR, USD, etc.)
 * @param description   Optional description for the recipient
 * @param metadata      Optional metadata (e.g., country, email)
 */
public record PaystackTransferRecipientRequest(
        String type,
        String name,
        @JsonProperty("account_number") String accountNumber,
        @JsonProperty("bank_code") String bankCode,
        String currency,
        String description,
        Object metadata
) {
    /**
     * Minimal constructor for common African market use cases.
     *
     * @param type          e.g., "nuban" for Nigeria, "mobile_money" for Ghana
     * @param name          Account holder name
     * @param accountNumber Account number or mobile money number
     * @param bankCode      Bank or provider code
     * @param currency      e.g., "NGN", "GHS", "ZAR"
     */
    public PaystackTransferRecipientRequest(String type, String name, String accountNumber, String bankCode, String currency) {
        this(type, name, accountNumber, bankCode, currency, null, null);
    }
}