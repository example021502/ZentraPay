package com.zentrapay.backend.service.common;

import lombok.RequiredArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

@RequiredArgsConstructor
public class Utils {

    public static String getZentag(String currencyCode, String phoneNumber) {
        return phoneNumber + "_" + currencyCode + "@zentrapay";
    }

    public static String getEntryId() {
        return NanoIdGenerator.generate("ENT_", 10);
    }

    public static String getRandomId(String prefix) {
        return NanoIdGenerator.generate(prefix, 10);
    }

    // generate a random id
    public static String getId(String prefix) {
        String string = UUID.randomUUID().toString().toLowerCase();
        return prefix + "_" + string.substring(string.length() - 10);
    }

    // True when the user is the receiver of this transaction
    public static boolean isCredit(UUID receiverId, UUID userId) {
        return userId.equals(receiverId);
    }

    public static String getSignedAmount(UUID receiverId, UUID userId, String sourceCurrencyCode, String destinationCurrencyCode, BigDecimal destinationAmount, BigDecimal sourceAmount) {
        boolean isCredit = isCredit(receiverId, userId);
        String sign = isCredit ? "+" : "-";
        // Credits arrive in the destination currency; debits leave in the
        // source currency (identical for wallet-to-wallet, differs for FX).
        String currencyCode = isCredit
                ? destinationCurrencyCode
                : sourceCurrencyCode;
        // A credit is what the receiver actually got (destination amount), a debit is what the sender paid
        BigDecimal amount = isCredit ? destinationAmount : sourceAmount;
        return sign + currencyCode + " " + (amount != null ? amount.setScale(2, java.math.RoundingMode.HALF_UP).toPlainString() : "0.00");
    }

}