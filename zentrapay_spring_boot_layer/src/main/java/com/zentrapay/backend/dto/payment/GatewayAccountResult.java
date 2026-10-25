package com.zentrapay.backend.dto.payment;

/** Neutral result of "who owns this bank account" on any gateway. */
public record GatewayAccountResult(String accountName, String accountNumber) {
}
