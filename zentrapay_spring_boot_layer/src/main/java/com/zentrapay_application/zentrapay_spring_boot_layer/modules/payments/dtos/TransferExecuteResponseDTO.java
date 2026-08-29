package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Response for POST /api/transfers/execute. Transfers are usually
 * asynchronous at the gateway (status pending/processing) — the webhook is
 * the source of truth for final settlement; this mirrors the gateway's
 * acknowledged state.
 */
public record TransferExecuteResponseDTO(
        UUID transactionId,
        /** Gateway that executed the payout (after any failover). */
        String gateway,
        String gatewayReference,
        String gatewayTransferCode,
        String status,
        BigDecimal amount,
        String currencyCode,
        String recipientName,
        String destination,
        /** Corridor flag: true when sender and recipient country match. */
        boolean national
) {
}