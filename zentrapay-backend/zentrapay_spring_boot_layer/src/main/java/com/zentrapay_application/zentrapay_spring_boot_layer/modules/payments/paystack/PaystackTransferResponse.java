package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.paystack;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Response wrapper for Paystack API calls.
 * <p>
 * Paystack returns all responses in a standard envelope:
 * <pre>
 * { "status": true, "message": "Transfer recipient created", "data": { ... } }
 * </pre>
 *
 * @param status  Whether the API call was successful
 * @param message Response message
 * @param data    Generic data object (typed at call site)
 * @param <T>     The expected data type
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record PaystackTransferResponse<T>(
        boolean status,
        String message,
        T data
) {
    /**
     * Data sub-object returned after creating a transfer recipient.
     */
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record TransferRecipientData(
            @JsonProperty("recipient_code") String recipientCode,
            @JsonProperty("active") boolean active,
            String type,
            String name,
            String currency,
            Details details
    ) {
        @JsonIgnoreProperties(ignoreUnknown = true)
        public record Details(
                @JsonProperty("account_number") String accountNumber,
                @JsonProperty("bank_code") String bankCode,
                @JsonProperty("bank_name") String bankName
        ) {}
    }

    /**
     * Data sub-object returned after initiating a transfer.
     */
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record TransferData(
            @JsonProperty("reference") String reference,
            @JsonProperty("amount") int amount,
            @JsonProperty("currency") String currency,
            @JsonProperty("status") String status,
            @JsonProperty("reason") String reason,
            @JsonProperty("transfer_code") String transferCode,
            @JsonProperty("id") long id,
            @JsonProperty("createdAt") String createdAt
    ) {}

    /**
     * Data sub-object returned when fetching transfer status.
     */
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record TransferStatusData(
            @JsonProperty("reference") String reference,
            @JsonProperty("amount") int amount,
            @JsonProperty("currency") String currency,
            @JsonProperty("status") String status,
            @JsonProperty("reason") String reason,
            @JsonProperty("transfer_code") String transferCode,
            @JsonProperty("failures") Object failures,
            @JsonProperty("id") long id,
            @JsonProperty("createdAt") String createdAt
    ) {}

    /**
     * Data sub-object for balance inquiries.
     */
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record BalanceData(
            @JsonProperty("currency") String currency,
            @JsonProperty("balance") long balance
    ) {}
}