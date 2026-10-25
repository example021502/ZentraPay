package com.zentrapay.backend.service.payment;

import com.zentrapay.backend.entity.FiatAccountModel;
import com.zentrapay.backend.entity.LedgerEntryModel;
import com.zentrapay.backend.entity.NotificationModel;
import com.zentrapay.backend.entity.TransactionModel;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.repository.*;
import com.zentrapay.backend.service.common.Datatypes;
import com.zentrapay.backend.service.common.NanoIdGenerator;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Set;
import java.util.UUID;

/**
 * Every balance change in the app goes through this class.
 *
 * <p>Golden rule: a balance change, its {@code transactions} row and its
 * {@code ledger_entries} rows are written in ONE database transaction. If anything
 * fails, all of it rolls back, so money can never be debited without a record.
 *
 * <p>The methods that move money after a transaction exists ({@link #markSubmitted},
 * {@link #complete}, {@link #refund}, {@link #creditFunding}, {@link #failFunding})
 * first LOCK the transaction row. That makes them safe to call twice (webhook
 * redelivery, webhook racing the reconciliation job): the second call sees the
 * final status and does nothing.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class LedgerOperations {

    // Statuses where the money is still "in flight" and the outcome is not final
    private static final Set<Datatypes.TransactionStatus> OPEN_STATUSES =
            Set.of(Datatypes.TransactionStatus.INITIATED, Datatypes.TransactionStatus.PENDING);

    private final FiatAccountRepository fiatAccountRepository;
    private final FiatWalletRepository fiatWalletRepository;
    private final TransactionRepository transactionRepository;
    private final LedgerEntryRepository ledgerEntryRepository;
    private final NotificationRepository notificationRepository;

    // ==================================================================
    // 1. Wallet -> wallet (P2P), fully inside our own ledger
    // ==================================================================

    /**
     * Moves money from one wallet account to another and records everything.
     * Debit, credit, transaction row, 2 ledger entries and 2 notifications are
     * all-or-nothing.
     *
     * @param draft          the transaction with sender/receiver details filled in (not saved yet)
     * @param sender         the account to debit (in {@code draft.amount}, source currency)
     * @param receiver       the account to credit (in {@code draft.destinationAmount}, destination currency)
     */
    @Transactional
    public TransactionModel transferBetweenWallets(TransactionModel draft, FiatAccountModel sender, FiatAccountModel receiver) {
        log.info("Ledger: P2P {} {} -> {} {}", draft.getAmount(), draft.getSourceCurrencyCode(),
                draft.getDestinationAmount(), draft.getDestinationCurrencyCode());

        // Always touch the two account rows in the same order (smaller id first), so two
        // people paying each other at the same moment cannot deadlock the database.
        boolean debitFirst = sender.getAccountId().compareTo(receiver.getAccountId()) < 0;
        if (debitFirst) {
            debit(sender.getAccountId(), draft.getAmount());
            credit(receiver.getAccountId(), draft.getDestinationAmount());
        } else {
            credit(receiver.getAccountId(), draft.getDestinationAmount());
            debit(sender.getAccountId(), draft.getAmount());
        }

        String entryId = NanoIdGenerator.generate("ENT_");
        draft.setEntryId(entryId);
        draft.setStatus(Datatypes.TransactionStatus.SUCCESS);
        TransactionModel txn = transactionRepository.save(draft);

        writeEntry(txn, entryId + "_DEBIT", sender.getAccountId(), Datatypes.LedgerEntryType.DEBIT,
                draft.getAmount(), draft.getSourceCurrencyCode(),
                "Sent to " + draft.getReceiverName());
        writeEntry(txn, entryId + "_CREDIT", receiver.getAccountId(), Datatypes.LedgerEntryType.CREDIT,
                draft.getDestinationAmount(), draft.getDestinationCurrencyCode(),
                "Received from " + draft.getSenderName());

        notify(txn.getSenderId(), txn, "Money Sent",
                "You sent " + txn.getSourceCurrencyCode() + " " + txn.getAmount().toPlainString() + " to " + txn.getReceiverName());
        notify(txn.getReceiverId(), txn, "Money Received",
                "You received " + txn.getDestinationCurrencyCode() + " " + txn.getDestinationAmount().toPlainString() + " from " + txn.getSenderName());
        return txn;
    }

    // ==================================================================
    // 2. Payout to the outside world (bank / mobile money)
    // ==================================================================

    /**
     * Step 1 of a payout: take the money from the sender and record the payment as
     * INITIATED (money is held, the gateway has not been called yet). The gateway
     * reference ({@code zp-<transactionId>}) is stored right away so webhooks can
     * always find the row.
     */
    @Transactional
    public TransactionModel debitForPayout(TransactionModel draft, FiatAccountModel sender) {
        log.info("Ledger: payout debit {} {} from account {}", draft.getAmount(), draft.getSourceCurrencyCode(), sender.getAccountId());
        debit(sender.getAccountId(), draft.getAmount());

        String entryId = NanoIdGenerator.generate("ENT_");
        draft.setEntryId(entryId);
        draft.setStatus(Datatypes.TransactionStatus.INITIATED);
        TransactionModel txn = transactionRepository.save(draft);
        txn.setExternalReferenceId(gatewayReference(txn));

        writeEntry(txn, entryId + "_DEBIT", sender.getAccountId(), Datatypes.LedgerEntryType.DEBIT,
                draft.getAmount(), draft.getSourceCurrencyCode(),
                "Transfer to " + draft.getReceiverName());
        return txn;
    }

    /** The reference we send to every gateway for this transaction (valid for Paystack: lowercase, 16+ chars). */
    public static String gatewayReference(TransactionModel txn) {
        return "zp-" + txn.getTransactionId();
    }

    /** Parses a gateway reference back into the transaction id, or null when it is not ours. */
    public static UUID transactionIdFromReference(String reference) {
        if (reference == null || !reference.startsWith("zp-")) {
            return null;
        }
        try {
            return UUID.fromString(reference.substring(3));
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    /**
     * Step 2 of a payout: the gateway accepted the transfer. INITIATED becomes PENDING
     * (or SUCCESS if the gateway already says delivered). If a webhook was faster and
     * already moved the status on, the status is left alone.
     */
    @Transactional
    public TransactionModel markSubmitted(UUID transactionId, UUID gatewayId, boolean settled) {
        TransactionModel txn = lock(transactionId);
        txn.setGatewayId(gatewayId);
        if (txn.getStatus() == Datatypes.TransactionStatus.INITIATED) {
            txn.setStatus(settled ? Datatypes.TransactionStatus.SUCCESS : Datatypes.TransactionStatus.PENDING);
            if (settled) {
                notify(txn.getSenderId(), txn, "Transfer Successful", successMessage(txn));
            }
        }
        return transactionRepository.save(txn);
    }

    /** Records which gateway is handling the payout (used before the call, so reconciliation knows where to look). */
    @Transactional
    public void assignGateway(UUID transactionId, UUID gatewayId) {
        TransactionModel txn = lock(transactionId);
        txn.setGatewayId(gatewayId);
        transactionRepository.save(txn);
    }

    /** The gateway confirmed delivery. Does nothing if the payment is already final. Returns true if it changed. */
    @Transactional
    public boolean complete(UUID transactionId) {
        TransactionModel txn = lock(transactionId);
        if (!OPEN_STATUSES.contains(txn.getStatus())) {
            log.info("Ledger: {} already {} - ignoring confirmation", txn.getInternalReferenceId(), txn.getStatus());
            return false;
        }
        txn.setStatus(Datatypes.TransactionStatus.SUCCESS);
        transactionRepository.save(txn);
        notify(txn.getSenderId(), txn, "Transfer Successful", successMessage(txn));
        return true;
    }

    /**
     * Gives the sender their money back and closes the payment as FAILED.
     * Also used when the gateway REVERSES a payout it had already settled
     * ({@code reversal = true}), which closes it as REVERSED instead.
     * Does nothing if the money was already returned. Returns true if it changed.
     */
    @Transactional
    public boolean refund(UUID transactionId, boolean reversal, String reason) {
        TransactionModel txn = lock(transactionId);
        boolean open = OPEN_STATUSES.contains(txn.getStatus());
        boolean settledThenReversed = reversal && txn.getStatus() == Datatypes.TransactionStatus.SUCCESS;
        if (!open && !settledThenReversed) {
            log.info("Ledger: {} is {} - nothing to refund", txn.getInternalReferenceId(), txn.getStatus());
            return false;
        }

        FiatAccountModel account = senderAccount(txn);
        credit(account.getAccountId(), txn.getAmount());
        writeEntry(txn, txn.getEntryId() + "_REFUND", account.getAccountId(), Datatypes.LedgerEntryType.CREDIT,
                txn.getAmount(), txn.getSourceCurrencyCode(), "Refund: " + txn.getInternalReferenceId());

        txn.setStatus(settledThenReversed ? Datatypes.TransactionStatus.REVERSED : Datatypes.TransactionStatus.FAILED);
        txn.setFailureReason(reason == null ? "Transfer failed at the payment gateway" : truncate(reason));
        transactionRepository.save(txn);

        notify(txn.getSenderId(), txn, "Transfer Failed",
                "Your transfer of " + txn.getSourceCurrencyCode() + " " + txn.getAmount().toPlainString()
                        + " to " + txn.getReceiverName() + " did not go through. The money was returned to your wallet.");
        log.info("Ledger: refunded {} {} for {}", txn.getAmount(), txn.getSourceCurrencyCode(), txn.getInternalReferenceId());
        return true;
    }

    // ==================================================================
    // 3. Wallet funding (money coming IN from a gateway checkout)
    // ==================================================================

    /**
     * Saves a new funding attempt as PENDING. No money moves until the gateway confirms.
     */
    @Transactional
    public TransactionModel recordFundingAttempt(TransactionModel draft) {
        draft.setEntryId(NanoIdGenerator.generate("ENT_"));
        draft.setStatus(Datatypes.TransactionStatus.PENDING);
        TransactionModel txn = transactionRepository.save(draft);
        txn.setExternalReferenceId(gatewayReference(txn));
        return txn;
    }

    /**
     * The gateway confirmed the customer paid: credit their wallet.
     * The amount and currency the gateway reports must match what we asked for,
     * otherwise nothing is credited and the payment is flagged as failed for review.
     *
     * @param paidAmount   what the gateway says was paid (major units)
     * @param paidCurrency what the gateway says was paid in
     */
    @Transactional
    public boolean creditFunding(UUID transactionId, BigDecimal paidAmount, String paidCurrency) {
        TransactionModel txn = lock(transactionId);
        if (!OPEN_STATUSES.contains(txn.getStatus())) {
            log.info("Ledger: funding {} already {} - ignoring", txn.getInternalReferenceId(), txn.getStatus());
            return false;
        }

        boolean currencyMatches = paidCurrency != null && paidCurrency.equalsIgnoreCase(txn.getDestinationCurrencyCode());
        boolean amountMatches = paidAmount != null && paidAmount.compareTo(txn.getAmount()) >= 0;
        if (!currencyMatches || !amountMatches) {
            log.error("Ledger: funding {} MISMATCH - expected {} {} but gateway reports {} {}. NOT credited.",
                    txn.getInternalReferenceId(), txn.getAmount(), txn.getDestinationCurrencyCode(), paidAmount, paidCurrency);
            txn.setStatus(Datatypes.TransactionStatus.FAILED);
            txn.setFailureReason("Paid amount did not match the request - needs manual review");
            transactionRepository.save(txn);
            return true;
        }

        FiatAccountModel account = receiverAccount(txn);
        credit(account.getAccountId(), txn.getAmount());
        writeEntry(txn, txn.getEntryId() + "_CREDIT", account.getAccountId(), Datatypes.LedgerEntryType.CREDIT,
                txn.getAmount(), txn.getDestinationCurrencyCode(), "Wallet funding: " + txn.getInternalReferenceId());

        txn.setStatus(Datatypes.TransactionStatus.SUCCESS);
        transactionRepository.save(txn);
        notify(txn.getReceiverId(), txn, "Wallet Funded",
                "Your wallet was topped up with " + txn.getDestinationCurrencyCode() + " " + txn.getAmount().toPlainString() + ".");
        return true;
    }

    /** The checkout failed or was abandoned: close it, nothing was credited. */
    @Transactional
    public boolean failFunding(UUID transactionId, String reason) {
        TransactionModel txn = lock(transactionId);
        if (!OPEN_STATUSES.contains(txn.getStatus())) {
            return false;
        }
        txn.setStatus(Datatypes.TransactionStatus.FAILED);
        txn.setFailureReason(truncate(reason == null ? "Checkout failed at the payment gateway" : reason));
        transactionRepository.save(txn);
        notify(txn.getReceiverId(), txn, "Wallet Funding Failed",
                "Your attempt to fund your wallet with " + txn.getDestinationCurrencyCode() + " " + txn.getAmount().toPlainString() + " did not go through.");
        return true;
    }

    // ==================================================================
    // Helpers
    // ==================================================================

    // Reads the transaction row with a database lock (see class comment)
    private TransactionModel lock(UUID transactionId) {
        return transactionRepository.findByIdForUpdate(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("Transaction not found"));
    }

    // Takes money out of an account; the UPDATE only succeeds when the balance is enough
    private void debit(UUID accountId, BigDecimal amount) {
        if (fiatAccountRepository.debit(accountId, amount) != 1) {
            throw new IllegalArgumentException("Insufficient balance");
        }
    }

    private void credit(UUID accountId, BigDecimal amount) {
        if (fiatAccountRepository.credit(accountId, amount) != 1) {
            throw new IllegalStateException("Could not credit account " + accountId);
        }
    }

    // Writes one ledger line; the running balance is read AFTER the balance update in this same transaction
    private void writeEntry(TransactionModel txn, String entryId, UUID accountId,
                            Datatypes.LedgerEntryType type, BigDecimal amount, String currency, String narration) {
        LedgerEntryModel entry = new LedgerEntryModel();
        entry.setTransactionId(txn.getTransactionId());
        entry.setEntryId(entryId);
        entry.setAccountId(accountId);
        entry.setType(type);
        entry.setAmount(amount);
        entry.setRunningBalance(fiatAccountRepository.getBalanceByAccountId(accountId).orElse(BigDecimal.ZERO));
        entry.setCurrencyCode(currency);
        entry.setNarration(truncate(narration));
        ledgerEntryRepository.save(entry);
    }

    // The sender's account in the currency that was debited
    private FiatAccountModel senderAccount(TransactionModel txn) {
        return accountFor(txn.getSenderId(), txn.getSourceCurrencyCode());
    }

    // The receiver's account in the currency that is credited
    private FiatAccountModel receiverAccount(TransactionModel txn) {
        return accountFor(txn.getReceiverId(), txn.getDestinationCurrencyCode());
    }

    private FiatAccountModel accountFor(UUID userId, String currencyCode) {
        UUID walletId = fiatWalletRepository.getWalletIdByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Wallet not found"));
        return fiatAccountRepository.findByWalletIdAndCurrencyCode(walletId, currencyCode)
                .orElseThrow(() -> new ResourceNotFoundException("No " + currencyCode + " account found"));
    }

    private void notify(UUID userId, TransactionModel txn, String title, String message) {
        if (userId == null) {
            return;
        }
        NotificationModel notification = new NotificationModel();
        notification.setUserId(userId);
        notification.setTitle(title);
        notification.setMessage(truncate(message));
        notification.setType(txn.getTransactionType().name());
        notification.setReferenceId(txn.getInternalReferenceId());
        notification.setIsRead(false);
        notificationRepository.save(notification);
    }

    private String successMessage(TransactionModel txn) {
        return "Your transfer of " + txn.getSourceCurrencyCode() + " " + txn.getAmount().toPlainString()
                + " to " + txn.getReceiverName() + " was successful.";
    }

    // Column limits are 255 (narration, failure reason) and 500 (notification message)
    private String truncate(String text) {
        return text.length() > 250 ? text.substring(0, 250) : text;
    }
}
