package com.zentrapay.backend.dto.payment;

import com.zentrapay.backend.service.common.Datatypes;
import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * POST /api/payments/initialize - send money from the signed-in user.
 *
 * <pre>
 * {
 *   "pin": "1234", "TXN_Ref": "...",
 *   "transactionType": "P2P_TRANSFER" | "CASH_OUT_BANK",
 *   "transfer": { "amount": 10, "currencyCode": "GHS", "purpose": "...", "destinationCurrencyCode"?: "GHS" },
 *   "appUser": { "userId": "...", "zentag": "..." }            // for P2P_TRANSFER
 *   "bank":    { "bankCode": "...", "accountNumber": "...", "accountName": "..." }   // for CASH_OUT_BANK
 * }
 * </pre>
 *
 * <p>The caller is always the SENDER (taken from the login token, never from the body).
 * {@code TXN_Ref} is the idempotency key: sending the same one again returns the first result
 * instead of paying twice. Older app builds send {@code channelType} (INTERNAL / BANK) instead
 * of {@code transactionType}; {@link #resolvedType()} understands both.
 */
public record TransactionRequest(
        @NotBlank(message = "PIN missing!")
        String pin,
        @NotBlank(message = "Transaction reference missing!")
        String TXN_Ref,
        @NotNull(message = "Transfer details missing!")
        @Valid
        TransferDetails transfer,
        @Valid
        AppUserDetails appUser,
        @Valid
        BankDetails bank,
        Datatypes.TransactionType transactionType,
        String channelType
) {

    /** Sending to another ZentraPay user. */
    public record AppUserDetails(
            @NotNull(message = "Recipient missing!")
            UUID userId,
            // May be blank when the app only knows the user id; the default account is used then
            String zentag
    ) {
    }

    /** Sending to a bank account. */
    public record BankDetails(
            UUID bankId,
            String bankName,
            @NotBlank(message = "Bank code missing!")
            String bankCode,
            @NotBlank(message = "Account number missing!")
            String accountNumber,
            @NotBlank(message = "Account name missing!")
            String accountName,
            // Country of the bank; defaults to the sender's country
            String countryCode
    ) {
    }

    /** The amount part of the payment. */
    public record TransferDetails(
            @NotNull(message = "Amount is required")
            @DecimalMin(value = "0.50", message = "Amount must be at least 0.50")
            BigDecimal amount,
            @NotBlank(message = "Currency code is required")
            String currencyCode,
            // Fiat only for now; crypto is rejected
            String currencyType,
            String purpose,
            // Currency the receiver gets; defaults to currencyCode (or the receiver's account currency)
            String destinationCurrencyCode,
            // Optional: the rate the app showed the user; rejected if it is no longer current
            UUID rateId
    ) {
    }

    /** The payment type, from {@code transactionType} or (older apps) {@code channelType}. */
    public Datatypes.TransactionType resolvedType() {
        if (transactionType != null) {
            return transactionType;
        }
        if ("INTERNAL".equalsIgnoreCase(channelType)) {
            return Datatypes.TransactionType.P2P_TRANSFER;
        }
        if ("BANK".equalsIgnoreCase(channelType)) {
            return Datatypes.TransactionType.CASH_OUT_BANK;
        }
        throw new IllegalArgumentException("Transaction type missing");
    }
}
