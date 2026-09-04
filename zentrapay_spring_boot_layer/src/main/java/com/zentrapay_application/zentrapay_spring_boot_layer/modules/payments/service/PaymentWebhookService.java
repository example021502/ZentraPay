package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.service;

import tools.jackson.databind.JsonNode;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.FiatWalletModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.NotificationModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.TransactionModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.FiatAccountRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.FiatWalletRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.NotificationRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

/**
 * Shared status-sync logic for both gateway webhooks (Paystack and
 * Flutterwave). The controllers only verify the inbound signature and parse
 * the payload into a generic {@link JsonNode}; every actual state
 * transition — flipping a {@code transactions} row's status and crediting
 * back a failed/reversed payout — happens here so the two gateways can't
 * drift into different behaviour.
 * <p>
 * Every write is idempotent on the transaction's current status: a webhook
 * that's redelivered (gateways retry on anything but a fast 200) must never
 * apply the same credit-back twice.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PaymentWebhookService {

    private static final String STATUS_PROCESSING = "processing";
    private static final String STATUS_SUCCESS = "success";
    private static final String STATUS_FAILED = "failed";

    private final TransactionRepository transactionRepository;
    private final FiatWalletRepository fiatWalletRepository;
    private final FiatAccountRepository fiatAccountRepository;
    private final NotificationRepository notificationRepository;

    // =====================================================================
    // Paystack
    // =====================================================================

    @Transactional
    public void handlePaystackEvent(JsonNode payload) {
        String event = textOrEmpty(payload, "event");
        JsonNode data = payload.path("data");
        String reference = textOrEmpty(data, "reference");

        log.info("Paystack webhook received: event={} reference={}", event, reference);

        switch (event) {
            case "transfer.success" -> resolveTransfer(reference, textOrEmpty(data, "transfer_code"), true, null);
            case "transfer.failed", "transfer.reversed" ->
                    resolveTransfer(reference, textOrEmpty(data, "transfer_code"), false, "Paystack: " + event);
            case "charge.success" -> resolveCharge(reference, true, null);
            case "charge.failed" -> resolveCharge(reference, false, "Paystack: charge failed");
            default -> log.info("Paystack webhook event {} ignored (no handler)", event);
        }
    }

    // =====================================================================
    // Flutterwave
    // =====================================================================

    @Transactional
    public void handleFlutterwaveEvent(JsonNode payload) {
        String event = textOrEmpty(payload, "event");
        JsonNode data = payload.path("data");
        String reference = textOrEmpty(data, "reference");
        String status = textOrEmpty(data, "status").toUpperCase();
        String externalId = data.hasNonNull("id") ? String.valueOf(data.path("id").asLong()) : "";

        log.info("Flutterwave webhook received: event={} reference={} status={}", event, reference, status);

        if (event.startsWith("transfer")) {
            boolean success = "SUCCESSFUL".equals(status) || "SUCCESS".equals(status);
            boolean terminalFailure = "FAILED".equals(status) || "REVERSED".equals(status);
            if (success) {
                resolveTransfer(reference, externalId, true, null);
            } else if (terminalFailure) {
                resolveTransfer(reference, externalId, false, "Flutterwave: transfer " + status.toLowerCase());
            } else {
                log.info("Flutterwave transfer webhook status {} is non-terminal, ignoring", status);
            }
        } else if (event.startsWith("charge")) {
            boolean success = "SUCCESSFUL".equals(status) || "SUCCESS".equals(status);
            resolveCharge(reference, success, success ? null : "Flutterwave: charge " + status.toLowerCase());
        } else {
            log.info("Flutterwave webhook event {} ignored (no handler)", event);
        }
    }

    // =====================================================================
    // Shared resolution logic
    // =====================================================================

    /**
     * Resolves an outbound payout (bank/mobile-money transfer) leg.
     * On failure/reversal, credits the sender's wallet back — this is the
     * other half of the money-safety guarantee {@code PaymentsService}'s
     * bank-transfer flow starts: a debit that never settles must not leave
     * the ledger permanently short.
     */
    private void resolveTransfer(String reference, String externalRef, boolean success, String failureReason) {
        Optional<TransactionModel> match = findByEitherReference(reference, externalRef);
        if (match.isEmpty()) {
            log.warn("Webhook for unknown transfer reference={} externalRef={} — acknowledging without action", reference, externalRef);
            return;
        }

        TransactionModel tx = match.get();
        if (!STATUS_PROCESSING.equalsIgnoreCase(tx.getStatus())) {
            log.info("Transfer {} already in terminal status {} — ignoring duplicate webhook", tx.getInternalReferenceId(), tx.getStatus());
            return;
        }

        if (!externalRef.isBlank() && (tx.getExternalReferenceId() == null || tx.getExternalReferenceId().isBlank())) {
            tx.setExternalReferenceId(externalRef);
        }

        if (success) {
            tx.setStatus(STATUS_SUCCESS);
            notify(tx.getSenderId(), tx.getInternalReferenceId(), "Transfer Successful",
                    "Your transfer of " + tx.getSourceCurrencyCode() + " " + tx.getAmount().toPlainString() + " to " + tx.getReceiverName() + " was successful.");
        } else {
            tx.setStatus(STATUS_FAILED);
            tx.setFailureReason(failureReason == null ? "Transfer failed at the gateway" : failureReason);
            // Comment: Credit-back — the original processBankTransfer debit
            // never actually settled, so the money must return to the sender.
            fiatWalletRepository.getWalletByUserId(tx.getSenderId()).ifPresentOrElse(
                    wallet -> fiatAccountRepository.credit(wallet.getWalletId(), tx.getAmount(), tx.getSourceCurrencyCode()),
                    () -> log.error("Could not credit back sender {} for failed transfer {} — wallet not found", tx.getSenderId(), tx.getInternalReferenceId())
            );
            notify(tx.getSenderId(), tx.getInternalReferenceId(), "Transfer Failed",
                    "Your transfer of " + tx.getSourceCurrencyCode() + " " + tx.getAmount().toPlainString() + " to " + tx.getReceiverName() + " failed and has been refunded.");
        }

        transactionRepository.save(tx);
    }

    /**
     * Resolves an inbound checkout (wallet funding via {@code /payments/initialize}).
     * On success, credits the payer's own wallet — this is the confirmation
     * step {@code PaymentsInitializeService} journals a pending leg for.
     */
    private void resolveCharge(String reference, boolean success, String failureReason) {
        Optional<TransactionModel> match = transactionRepository.findByInternalReferenceId(reference);
        if (match.isEmpty()) {
            log.warn("Webhook for unknown charge reference={} — acknowledging without action", reference);
            return;
        }

        TransactionModel tx = match.get();
        if (!STATUS_PROCESSING.equalsIgnoreCase(tx.getStatus())) {
            log.info("Charge {} already in terminal status {} — ignoring duplicate webhook", tx.getInternalReferenceId(), tx.getStatus());
            return;
        }

        if (success) {
            tx.setStatus(STATUS_SUCCESS);
            FiatWalletModel wallet = fiatWalletRepository.getWalletByUserId(tx.getReceiverId()).orElse(null);
            if (wallet != null) {
                fiatAccountRepository.credit(wallet.getWalletId(), tx.getAmount(), tx.getSourceCurrencyCode());
            } else {
                log.error("Could not credit payer {} for confirmed checkout {} — wallet not found", tx.getReceiverId(), tx.getInternalReferenceId());
            }
            notify(tx.getReceiverId(), tx.getInternalReferenceId(), "Wallet Funded",
                    "Your wallet was topped up with " + tx.getSourceCurrencyCode() + " " + tx.getAmount().toPlainString() + ".");
        } else {
            tx.setStatus(STATUS_FAILED);
            tx.setFailureReason(failureReason == null ? "Checkout failed at the gateway" : failureReason);
            notify(tx.getReceiverId(), tx.getInternalReferenceId(), "Wallet Funding Failed",
                    "Your attempt to fund your wallet with " + tx.getSourceCurrencyCode() + " " + tx.getAmount().toPlainString() + " failed.");
        }

        transactionRepository.save(tx);
    }

    private Optional<TransactionModel> findByEitherReference(String internalRef, String externalRef) {
        if (internalRef != null && !internalRef.isBlank()) {
            Optional<TransactionModel> byInternal = transactionRepository.findByInternalReferenceId(internalRef);
            if (byInternal.isPresent()) {
                return byInternal;
            }
        }
        if (externalRef != null && !externalRef.isBlank()) {
            return transactionRepository.findByExternalReferenceId(externalRef);
        }
        return Optional.empty();
    }

    private void notify(java.util.UUID userId, String reference, String title, String message) {
        NotificationModel notification = new NotificationModel();
        notification.setUserId(userId);
        notification.setReferenceId(reference);
        notification.setTitle(title);
        notification.setMessage(message);
        notification.setType("TRANSFER");
        notification.setIsRead(false);
        notificationRepository.save(notification);
    }

    private String textOrEmpty(JsonNode node, String field) {
        JsonNode value = node.path(field);
        return value.isMissingNode() || value.isNull() ? "" : value.asText("");
    }
}
