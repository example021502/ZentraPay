package com.zentrapay.backend.service.payment;

import com.zentrapay.backend.dto.payment.GatewayChargeStatus;
import com.zentrapay.backend.entity.GatewayModel;
import com.zentrapay.backend.entity.TransactionModel;
import com.zentrapay.backend.exception.PaymentGatewayException;
import com.zentrapay.backend.repository.TransactionRepository;
import com.zentrapay.backend.service.common.Datatypes;
import com.zentrapay.backend.service.gateway.FlutterwaveServices;
import com.zentrapay.backend.service.gateway.GatewayServices;
import com.zentrapay.backend.service.gateway.PaystackServices;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Safety net for payments whose webhook never arrived (or whose gateway call timed out).
 *
 * <p>Every few minutes it looks at payments still INITIATED / PENDING after a grace period,
 * asks the gateway directly what happened, and applies the same result a webhook would have:
 * <ul>
 *   <li>payout delivered   -> SUCCESS</li>
 *   <li>payout failed      -> sender refunded</li>
 *   <li>payout unknown to the gateway and still INITIATED -> the call never reached it, refund</li>
 *   <li>checkout paid      -> wallet credited (amount verified)</li>
 * </ul>
 * Applying a result twice is harmless (see LedgerOperations), so this can overlap with webhooks.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PaymentReconciliationService {

    private static final int BATCH_SIZE = 50;

    private final TransactionRepository transactionRepository;
    private final PaymentWebhookService webhookService;
    private final GatewayServices gatewayServices;
    private final PaystackServices paystackServices;
    private final FlutterwaveServices flutterwaveServices;

    // How long a payment may stay open before we go and ask the gateway about it
    @Value("${app.reconcile.grace-minutes:10}")
    private long graceMinutes;

    /** Runs on a timer; also safe to call by hand. */
    @Scheduled(fixedDelayString = "${app.reconcile.interval-ms:300000}", initialDelayString = "${app.reconcile.initial-delay-ms:120000}")
    public void reconcileOpenPayments() {
        LocalDateTime cutoff = LocalDateTime.now().minusMinutes(graceMinutes);
        List<TransactionModel> open = transactionRepository.findOpenBefore(
                List.of(Datatypes.TransactionStatus.INITIATED, Datatypes.TransactionStatus.PENDING),
                cutoff, PageRequest.of(0, BATCH_SIZE));
        if (open.isEmpty()) {
            return;
        }

        log.info("Reconciliation: checking {} open payment(s)", open.size());
        for (TransactionModel txn : open) {
            try {
                reconcile(txn);
            } catch (Exception e) {
                // One bad row must not stop the others; it is retried on the next run
                log.warn("Reconciliation: could not check {}: {}", txn.getInternalReferenceId(), e.getMessage());
            }
        }
    }

    private void reconcile(TransactionModel txn) {
        if (txn.getGatewayId() == null) {
            log.warn("Reconciliation: {} has no gateway - needs manual review", txn.getInternalReferenceId());
            return;
        }
        if (txn.getTransactionType() == Datatypes.TransactionType.BILL_PAYMENT) {
            // Bills have no transfer status to poll; they are settled by the biller callback / manual review
            log.warn("Reconciliation: bill payment {} is still {} - needs manual review", txn.getInternalReferenceId(), txn.getStatus());
            return;
        }
        GatewayModel gateway = gatewayServices.gatewayById(txn.getGatewayId());
        String reference = LedgerOperations.gatewayReference(txn);
        boolean funding = txn.getTransactionType() == Datatypes.TransactionType.CASH_IN_CARD
                || txn.getTransactionType() == Datatypes.TransactionType.CASH_IN_BANK
                || txn.getTransactionType() == Datatypes.TransactionType.CASH_IN_MOMO;

        if (funding) {
            reconcileFunding(gateway, txn, reference);
        } else {
            reconcilePayout(gateway, txn, reference);
        }
    }

    // Wallet top-up: credit if the gateway says it was paid, close it if it failed
    private void reconcileFunding(GatewayModel gateway, TransactionModel txn, String reference) {
        GatewayChargeStatus status;
        try {
            status = switch (gatewayServices.nameOf(gateway)) {
                case PAYSTACK -> paystackServices.chargeStatus(reference);
                case FLUTTERWAVE -> flutterwaveServices.chargeStatus(reference);
                default -> null;
            };
        } catch (PaymentGatewayException e) {
            // "No such checkout" for more than a day: the customer never paid, close it
            boolean old = txn.getCreatedAt() != null && txn.getCreatedAt().isBefore(LocalDateTime.now().minusDays(1));
            if (!e.isOutcomeUnknown() && old) {
                webhookService.checkoutFailed(reference, "Checkout was never completed");
            }
            return;
        }
        if (status == null) {
            return;
        }
        if (status.successful()) {
            webhookService.checkoutPaid(reference, status.amount(), status.currency());
        } else if (status.finalFailure()) {
            webhookService.checkoutFailed(reference, gateway.getProviderName() + ": checkout not completed");
        }
    }

    // Payout: apply whatever final state the gateway reports
    private void reconcilePayout(GatewayModel gateway, TransactionModel txn, String reference) {
        String status;
        try {
            status = switch (gatewayServices.nameOf(gateway)) {
                case PAYSTACK -> paystackServices.transferStatus(reference);
                case FLUTTERWAVE -> flutterwaveServices.transferStatus(reference).toLowerCase();
                default -> "unknown";
            };
        } catch (PaymentGatewayException e) {
            // The gateway answered "no such transfer": if we never got past INITIATED, the call never reached it
            if (!e.isOutcomeUnknown() && txn.getStatus() == Datatypes.TransactionStatus.INITIATED) {
                log.warn("Reconciliation: {} is unknown to {} - refunding", txn.getInternalReferenceId(), gateway.getProviderName());
                webhookService.payoutFailed(reference, false, "Transfer was never received by " + gateway.getProviderName());
            }
            return;
        }

        switch (status) {
            case "success", "successful" -> webhookService.payoutSucceeded(reference);
            case "failed" -> webhookService.payoutFailed(reference, false, gateway.getProviderName() + ": transfer failed");
            case "reversed" -> webhookService.payoutFailed(reference, true, gateway.getProviderName() + ": transfer reversed");
            default -> log.info("Reconciliation: {} is still {} at {}", txn.getInternalReferenceId(), status, gateway.getProviderName());
        }
    }
}
