package com.zentrapay.backend.service.payment;

import com.zentrapay.backend.entity.TransactionModel;
import com.zentrapay.backend.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import tools.jackson.databind.JsonNode;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

/**
 * Applies gateway webhook events to our transactions.
 *
 * <p>The controllers only check the signature and parse the JSON; every status change
 * happens here, through {@link LedgerOperations}, so all three gateways behave the same:
 * <ul>
 *   <li>payout confirmed          -> transaction SUCCESS</li>
 *   <li>payout failed             -> sender refunded, transaction FAILED</li>
 *   <li>payout reversed later     -> sender refunded, transaction REVERSED</li>
 *   <li>checkout paid             -> wallet credited (amount and currency verified), SUCCESS</li>
 *   <li>checkout failed           -> transaction FAILED, nothing credited</li>
 * </ul>
 *
 * <p>Gateways resend webhooks and may deliver the same event twice. That is safe: the ledger
 * methods lock the transaction row and ignore anything that is already final.
 * An event for a reference we do not know is acknowledged and ignored.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PaymentWebhookService {

    private final LedgerOperations ledgerOperations;
    private final TransactionRepository transactionRepository;

    // ==================================================================
    // Paystack
    // ==================================================================

    /** Paystack events: transfer.success / transfer.failed / transfer.reversed / charge.success. */
    public void handlePaystackEvent(JsonNode payload) {
        String event = text(payload, "event");
        JsonNode data = payload.path("data");
        String reference = text(data, "reference");
        log.info("Paystack webhook: event={} reference={}", event, reference);

        switch (event) {
            case "transfer.success" -> payoutSucceeded(reference);
            case "transfer.failed" -> payoutFailed(reference, false, "Paystack: transfer failed");
            case "transfer.reversed" -> payoutFailed(reference, true, "Paystack: transfer reversed");
            case "charge.success" -> checkoutPaid(reference,
                    data.path("amount").isNumber() ? data.path("amount").decimalValue().movePointLeft(2) : null,
                    text(data, "currency"));
            default -> log.info("Paystack webhook event {} ignored (no handler)", event);
        }
    }

    // ==================================================================
    // Flutterwave
    // ==================================================================

    /** Flutterwave events: transfer.completed (payouts) and charge.completed (checkouts). */
    public void handleFlutterwaveEvent(JsonNode payload) {
        String event = text(payload, "event");
        JsonNode data = payload.path("data");
        String status = text(data, "status").toUpperCase();
        log.info("Flutterwave webhook: event={} status={}", event, status);

        if (event.startsWith("transfer")) {
            String reference = text(data, "reference");
            switch (status) {
                case "SUCCESSFUL", "SUCCESS" -> payoutSucceeded(reference);
                case "FAILED" -> payoutFailed(reference, false, "Flutterwave: transfer failed");
                case "REVERSED" -> payoutFailed(reference, true, "Flutterwave: transfer reversed");
                default -> log.info("Flutterwave transfer status {} is not final, ignoring", status);
            }
        } else if (event.startsWith("charge")) {
            // For checkouts Flutterwave puts OUR reference in tx_ref
            String reference = text(data, "tx_ref");
            if ("SUCCESSFUL".equals(status) || "SUCCESS".equals(status)) {
                checkoutPaid(reference, data.path("amount").isNumber() ? data.path("amount").decimalValue() : null, text(data, "currency"));
            } else if ("FAILED".equals(status)) {
                checkoutFailed(reference, "Flutterwave: charge failed");
            }
        } else {
            log.info("Flutterwave webhook event {} ignored (no handler)", event);
        }
    }

    // ==================================================================
    // Onafriq
    // ==================================================================

    /**
     * Onafriq payout events: {event, data:{reference, status}}.
     * (The exact payload must be confirmed once the Onafriq partner account exists.)
     */
    public void handleOnafriqEvent(JsonNode payload) {
        JsonNode data = payload.path("data");
        String reference = text(data, "reference");
        String status = text(data, "status").toUpperCase();
        log.info("Onafriq webhook: reference={} status={}", reference, status);

        switch (status) {
            case "SUCCESSFUL", "SUCCESS", "COMPLETED" -> payoutSucceeded(reference);
            case "FAILED", "REJECTED" -> payoutFailed(reference, false, "Onafriq: transfer failed");
            case "REVERSED" -> payoutFailed(reference, true, "Onafriq: transfer reversed");
            default -> log.info("Onafriq status {} is not final, ignoring", status);
        }
    }

    // ==================================================================
    // Shared resolution (also used by the reconciliation job)
    // ==================================================================

    /** The gateway says the payout was delivered. */
    public void payoutSucceeded(String reference) {
        findTransaction(reference).ifPresent(txn -> ledgerOperations.complete(txn.getTransactionId()));
    }

    /** The gateway says the payout failed (or took it back): refund the sender. */
    public void payoutFailed(String reference, boolean reversal, String reason) {
        findTransaction(reference).ifPresent(txn -> ledgerOperations.refund(txn.getTransactionId(), reversal, reason));
    }

    /** The gateway says the customer paid: credit their wallet (only if amount and currency match). */
    public void checkoutPaid(String reference, BigDecimal paidAmount, String paidCurrency) {
        findTransaction(reference).ifPresent(txn -> ledgerOperations.creditFunding(txn.getTransactionId(), paidAmount, paidCurrency));
    }

    /** The checkout failed or was abandoned: close it without crediting anything. */
    public void checkoutFailed(String reference, String reason) {
        findTransaction(reference).ifPresent(txn -> ledgerOperations.failFunding(txn.getTransactionId(), reason));
    }

    // The reference we sent to the gateway is "zp-<transactionId>"; fall back to the stored references
    private Optional<TransactionModel> findTransaction(String reference) {
        if (reference == null || reference.isBlank()) {
            log.warn("Webhook without a reference - ignored");
            return Optional.empty();
        }
        UUID id = LedgerOperations.transactionIdFromReference(reference);
        Optional<TransactionModel> txn = id == null
                ? transactionRepository.findByExternalReferenceId(reference)
                : transactionRepository.findById(id);
        if (txn.isEmpty()) {
            txn = transactionRepository.findByInternalReferenceId(reference);
        }
        if (txn.isEmpty()) {
            log.warn("Webhook for unknown reference {} - acknowledged and ignored", reference);
        }
        return txn;
    }

    private String text(JsonNode node, String field) {
        return node.path(field).asString("");
    }
}
