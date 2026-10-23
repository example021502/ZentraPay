package com.zentrapay.backend.dto.payment;

/**
 * Neutral result of "send this payout" on any gateway.
 *
 * @param gatewayCode the gateway's own code/id for the transfer (for support / reconciliation)
 * @param settled     true when the gateway already reports the money as delivered;
 *                    false when it only accepted it (the webhook confirms it later)
 */
public record GatewayTransferResult(String gatewayCode, boolean settled) {
}
