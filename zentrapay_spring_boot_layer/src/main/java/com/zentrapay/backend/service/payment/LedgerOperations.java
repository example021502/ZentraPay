// Updated LedgerOperations class aligned with TransactionsServices and AccountsServices
package com.zentrapay.backend.service.payment;

import com.zentrapay.backend.entity.AccountsModel;
import com.zentrapay.backend.entity.LedgerEntryModel;
import com.zentrapay.backend.entity.NotificationModel;
import com.zentrapay.backend.entity.TransactionModel;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.repository.LedgerEntryRepository;
import com.zentrapay.backend.repository.NotificationRepository;
import com.zentrapay.backend.service.DigitalAccounts.AccountsServices;
import com.zentrapay.backend.service.common.Datatypes;
import com.zentrapay.backend.service.common.NanoIdGenerator;
import com.zentrapay.backend.service.transaction.TransactionsServices;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Set;
import java.util.UUID;

/**
 * Coordinates balance movements via {@link TransactionsServices}, account lookups/locks
 * via {@link AccountsServices}, and append-only ledger entries via {@link LedgerEntryRepository}.
 *
 * <p>Golden rule: a balance change, its {@code transactions} row and its
 * {@code ledger_entries} rows are written in ONE database transaction. If anything
 * fails, all of it rolls back, so money can never be debited without a record.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class LedgerOperations {

    // Statuses where the money is still "in flight" and the outcome is not final
    private static final Set<Datatypes.TransactionStatus> OPEN_STATUSES =
            Set.of(Datatypes.TransactionStatus.INITIATED, Datatypes.TransactionStatus.PENDING);

    private final LedgerEntryRepository ledgerEntryRepository;
    private final NotificationRepository notificationRepository;
    private final AccountsServices accountsServices;
    private final TransactionsServices transactionsServices;

    // ==================================================================
    // Ledger entry helpers (DEBIT / CREDIT rows in ledger_entries)
    // ==================================================================

    /**
     * Records a DEBIT entry in the ledger table with its post-operation running balance.
     */
    @Transactional
    public void debit(
            UUID transactionId,
            String entryId,
            String accountReference,
            BigDecimal amount,
            BigDecimal balance,
            String currencyCode,
            String narration
    ) {
        // Persist a DEBIT ledger entry for the affected account
        log.info("===== LEDGER DEBIT LEG... =====");

        LedgerEntryModel l = new LedgerEntryModel();
        l.setTransactionId(transactionId);
        l.setEntryId("DEBIT_" + entryId);
        l.setAccountReference(accountReference);
        l.setType(Datatypes.LedgerEntryType.DEBIT);
        l.setAmount(amount);
        l.setRunningBalance(balance);
        l.setCurrencyCode(currencyCode);
        l.setNarration(truncate(narration));
        ledgerEntryRepository.save(l);
    }

    /**
     * Records a CREDIT entry in the ledger table with its post-operation running balance.
     */
    @Transactional
    public void credit(
            UUID transactionId,
            String entryId,
            String accountReference,
            BigDecimal amount,
            BigDecimal balance,
            String currencyCode,
            String narration
    ) {
        // Persist a CREDIT ledger entry for the affected account
        log.info("===== LEDGER CREDIT LEG... =====");

        LedgerEntryModel l = new LedgerEntryModel();
        l.setTransactionId(transactionId);
        l.setEntryId("CREDIT_" + entryId);
        l.setAccountReference(accountReference);
        l.setType(Datatypes.LedgerEntryType.CREDIT);
        l.setAmount(amount);
        l.setRunningBalance(balance);
        l.setCurrencyCode(currencyCode);
        l.setNarration(truncate(narration));
        ledgerEntryRepository.save(l);
    }

    // ==================================================================
    // 1. Wallet -> wallet (P2P), fully inside our own ledger
    // ==================================================================

    /**
     * Moves money from one wallet account to another and records everything.
     * Debit, credit, transaction row, 2 ledger entries and 2 notifications are
     * all-or-nothing.
     */
    @Transactional
    public TransactionModel transferBetweenWallets(TransactionModel draft, AccountsModel sender, AccountsModel receiver) {
        log.info("Ledger: P2P {} {} -> {} {}", draft.getAmount(), draft.getSourceCurrencyCode(),
                draft.getDestinationAmount(), draft.getDestinationCurrencyCode());

        // Lock and move balances in deterministic UUID order to prevent deadlocks
        boolean debitFirst = sender.getId().compareTo(receiver.getId()) < 0;
        BigDecimal senderBalance;
        BigDecimal receiverBalance;

        if (debitFirst) {
            senderBalance = moveDebit(sender.getId(), draft.getAmount(), draft.getSourceCurrencyCode());
            receiverBalance = moveCredit(receiver.getId(), draft.getDestinationAmount(), draft.getDestinationCurrencyCode());
        } else {
            receiverBalance = moveCredit(receiver.getId(), draft.getDestinationAmount(), draft.getDestinationCurrencyCode());
            senderBalance = moveDebit(sender.getId(), draft.getAmount(), draft.getSourceCurrencyCode());
        }

        String entryId = NanoIdGenerator.generate("ENT_", 10);
        draft.setEntryId(entryId);
        draft.setStatus(Datatypes.TransactionStatus.SUCCESS);
        TransactionModel txn = transactionsServices.save(draft);

        debit(txn.getId(), entryId + "_W2W", sender.getZentag(),
                draft.getAmount(), senderBalance, draft.getSourceCurrencyCode(),
                "Sent to " + draft.getReceiverName());
        credit(txn.getId(), entryId + "_W2W", receiver.getZentag(),
                draft.getDestinationAmount(), receiverBalance, draft.getDestinationCurrencyCode(),
                "Received from " + txn.getSenderName());

        notify(txn.getSenderId(), txn, "Money Sent",
                "You sent " + txn.getSourceCurrencyCode() + " " + txn.getAmount().toPlainString() + " to " + txn.getReceiverName());
        notify(txn.getReceiverId(), txn, "Money Received",
                "You received " + txn.getDestinationCurrencyCode() + " " + txn.getDestinationAmount().toPlainString() + " from " + txn.getSenderName());
        return txn;
    }

    /**
     * Parses a gateway reference back into the transaction id, or null when it is not ours.
     */
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
     * (or SUCCESS if the gateway already says delivered).
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
        return transactionsServices.save(txn);
    }

    /**
     * Records which gateway is handling the payout (used before the call, so reconciliation knows where to look).
     */
    @Transactional
    public void assignGateway(UUID transactionId, UUID gatewayId) {
        TransactionModel txn = lock(transactionId);
        txn.setGatewayId(gatewayId);
        transactionsServices.save(txn);
    }

    /**
     * The gateway confirmed delivery. Does nothing if the payment is already final. Returns true if it changed.
     */
    @Transactional
    public void complete(UUID transactionId) {
        TransactionModel txn = lock(transactionId);
        if (!OPEN_STATUSES.contains(txn.getStatus())) {
            log.info("Ledger: {} already {} - ignoring confirmation", txn.getInternalReferenceId(), txn.getStatus());
        }
        txn.setStatus(Datatypes.TransactionStatus.SUCCESS);
        transactionsServices.save(txn);
        notify(txn.getSenderId(), txn, "Transfer Successful", successMessage(txn));
    }

    /**
     * Gives the sender their money back and closes the payment as FAILED (or REVERSED when reversal = true).
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

        AccountsModel account = senderAccount(txn);
        BigDecimal newBalance = moveCredit(account.getId(), txn.getAmount(), txn.getSourceCurrencyCode());
        credit(txn.getId(), txn.getEntryId() + "_REFUND", account.getZentag(),
                txn.getAmount(), newBalance, txn.getSourceCurrencyCode(), "Refund: " + txn.getInternalReferenceId());

        txn.setStatus(settledThenReversed ? Datatypes.TransactionStatus.REVERSED : Datatypes.TransactionStatus.FAILED);
        txn.setFailureReason(reason == null ? "Transfer failed at the payment gateway" : truncate(reason));
        transactionsServices.save(txn);

        notify(txn.getSenderId(), txn, "Transfer Failed",
                "Your transfer of " + txn.getSourceCurrencyCode() + " " + txn.getAmount().toPlainString()
                        + " to " + txn.getReceiverName() + " did not go through. The money was returned to your wallet.");
        log.info("Ledger: refunded {} {} for {}", txn.getAmount(), txn.getSourceCurrencyCode(), txn.getInternalReferenceId());
        return true;
    }

    // ==================================================================
    // 2b. Bill payment settlement & reversal
    // ==================================================================

    /**
     * Settles a confirmed bill payment by moving funds from the pending bills clearing
     * account to the provider float account and writing balanced debit/credit ledger entries.
     */
    @Transactional
    public boolean settleBillSuccess(
            UUID transactionId,
            String entryId,
            UUID pendingBillsClearingAccountId,
            UUID providerFloatAccountId,
            BigDecimal amount,
            String currencyCode
    ) {
        // Lock transaction first so concurrent webhook/poller invocations are idempotent
        TransactionModel txn = lock(transactionId);
        if (!OPEN_STATUSES.contains(txn.getStatus())) {
            log.info("Ledger: bill {} already {} - ignoring settlement", txn.getInternalReferenceId(), txn.getStatus());
            return false;
        }

        // Lock both internal accounts in deterministic UUID order to prevent deadlocks
        UUID firstId = pendingBillsClearingAccountId.compareTo(providerFloatAccountId) < 0
                ? pendingBillsClearingAccountId : providerFloatAccountId;
        UUID secondId = firstId.equals(pendingBillsClearingAccountId)
                ? providerFloatAccountId : pendingBillsClearingAccountId;

        lockAccountById(firstId);
        lockAccountById(secondId);

        // Move funds out of pending bills clearing and into provider float via TransactionsServices
        BigDecimal clearingBalance = moveDebit(pendingBillsClearingAccountId, amount, currencyCode);
        BigDecimal floatBalance = moveCredit(providerFloatAccountId, amount, currencyCode);

        String clearingRef = accountsServices.getAccount(pendingBillsClearingAccountId).getZentag();
        String floatRef = accountsServices.getAccount(providerFloatAccountId).getZentag();

        String baseEntryId = (entryId != null && !entryId.isBlank())
                ? entryId
                : (txn.getEntryId() != null ? txn.getEntryId() : NanoIdGenerator.generate("ENT_", 12));

        debit(txn.getId(), baseEntryId + "_BILL_CLEARING", clearingRef,
                amount, clearingBalance, currencyCode,
                "Settled bill payment from pending clearing: " + txn.getInternalReferenceId());
        credit(txn.getId(), baseEntryId + "_BILL_FLOAT", floatRef,
                amount, floatBalance, currencyCode,
                "Bill payment settled into provider float: " + txn.getInternalReferenceId());

        txn.setStatus(Datatypes.TransactionStatus.SUCCESS);
        transactionsServices.save(txn);
        notify(txn.getSenderId(), txn, "Bill Payment Successful",
                "Your bill payment of " + currencyCode + " " + amount.toPlainString()
                        + " to " + txn.getReceiverName() + " was completed.");
        return true;
    }

    /**
     * Refunds a failed or rejected bill payment by debiting the pending bills clearing
     * account and crediting the customer's wallet account back.
     */
    @Transactional
    public boolean refundFailedBill(
            UUID transactionId,
            String entryId,
            UUID pendingBillsClearingAccountId,
            UUID userWalletAccountId,
            BigDecimal amount,
            String currencyCode
    ) {
        // Lock transaction first so duplicate failure callbacks cannot double-refund
        TransactionModel txn = lock(transactionId);
        if (!OPEN_STATUSES.contains(txn.getStatus())) {
            log.info("Ledger: bill {} already {} - ignoring refund", txn.getInternalReferenceId(), txn.getStatus());
            return false;
        }

        // Lock both accounts in deterministic UUID order to prevent deadlocks
        UUID firstId = pendingBillsClearingAccountId.compareTo(userWalletAccountId) < 0
                ? pendingBillsClearingAccountId : userWalletAccountId;
        UUID secondId = firstId.equals(pendingBillsClearingAccountId)
                ? userWalletAccountId : pendingBillsClearingAccountId;

        lockAccountById(firstId);
        lockAccountById(secondId);

        // Release pending bills clearing hold and credit user wallet account via TransactionsServices
        BigDecimal clearingBalance = moveDebit(pendingBillsClearingAccountId, amount, currencyCode);
        BigDecimal walletBalance = moveCredit(userWalletAccountId, amount, currencyCode);

        String clearingRef = accountsServices.getAccount(pendingBillsClearingAccountId).getZentag();
        String walletRef = accountsServices.getAccount(userWalletAccountId).getZentag();

        String baseEntryId = (entryId != null && !entryId.isBlank())
                ? entryId
                : (txn.getEntryId() != null ? txn.getEntryId() : NanoIdGenerator.generate("ENT_", 12));

        debit(txn.getId(), baseEntryId + "_BILL_CLEARING_REFUND", clearingRef,
                amount, clearingBalance, currencyCode,
                "Released pending bills clearing on failed bill: " + txn.getInternalReferenceId());
        credit(txn.getId(), baseEntryId + "_BILL_REFUND", walletRef,
                amount, walletBalance, currencyCode,
                "Refunded failed bill payment: " + txn.getInternalReferenceId());

        txn.setStatus(Datatypes.TransactionStatus.FAILED);
        txn.setFailureReason("Bill payment failed at gateway");
        transactionsServices.save(txn);
        notify(txn.getSenderId(), txn, "Bill Payment Failed",
                "Your bill payment of " + currencyCode + " " + amount.toPlainString()
                        + " to " + txn.getReceiverName() + " failed. The money was returned to your wallet.");
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
        draft.setEntryId(NanoIdGenerator.generate("ENT_", 21));
        draft.setStatus(Datatypes.TransactionStatus.PENDING);
        TransactionModel txn = transactionsServices.save(draft);
        txn.setExternalReferenceId(gatewayReference(txn));
        return txn;
    }

    /**
     * The gateway confirmed the customer paid: credit their wallet.
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
            transactionsServices.save(txn);
            return true;
        }

        AccountsModel account = receiverAccount(txn);
        BigDecimal newBalance = moveCredit(account.getId(), txn.getAmount(), txn.getDestinationCurrencyCode());
        credit(txn.getId(), txn.getEntryId() + "_FUNDING", account.getZentag(),
                txn.getAmount(), newBalance, txn.getDestinationCurrencyCode(), "Wallet funding: " + txn.getInternalReferenceId());

        txn.setStatus(Datatypes.TransactionStatus.SUCCESS);
        transactionsServices.save(txn);
        notify(txn.getReceiverId(), txn, "Wallet Funded",
                "Your wallet was topped up with " + txn.getDestinationCurrencyCode() + " " + txn.getAmount().toPlainString() + ".");
        return true;
    }

    /**
     * The checkout failed or was abandoned: close it, nothing was credited.
     */
    @Transactional
    public boolean failFunding(UUID transactionId, String reason) {
        TransactionModel txn = lock(transactionId);
        if (!OPEN_STATUSES.contains(txn.getStatus())) {
            return false;
        }
        txn.setStatus(Datatypes.TransactionStatus.FAILED);
        txn.setFailureReason(truncate(reason == null ? "Checkout failed at the payment gateway" : reason));
        transactionsServices.save(txn);
        notify(txn.getReceiverId(), txn, "Wallet Funding Failed",
                "Your attempt to fund your wallet with " + txn.getDestinationCurrencyCode() + " " + txn.getAmount().toPlainString() + " did not go through.");
        return true;
    }

    // ==================================================================
    // 4. Internal moves (savings goals, loans): wallet account <-> ZentraPay product
    // ==================================================================

    /**
     * Takes money out of one of the user's wallet accounts for a ZentraPay product.
     */
    @Transactional
    public TransactionModel debitInternal(TransactionModel draft, AccountsModel account, String narration, String notifyTitle, String notifyMessage) {
        BigDecimal newBalance = moveDebit(account.getId(), draft.getAmount(), draft.getSourceCurrencyCode());
        String entryId = NanoIdGenerator.generate("ENT_", 21);
        draft.setEntryId(entryId);
        draft.setStatus(Datatypes.TransactionStatus.SUCCESS);
        TransactionModel txn = transactionsServices.save(draft);
        debit(txn.getId(), entryId + "_INTERNAL", account.getZentag(),
                draft.getAmount(), newBalance, draft.getSourceCurrencyCode(), narration);
        notify(txn.getSenderId(), txn, notifyTitle, notifyMessage);
        return txn;
    }

    /**
     * Puts money into one of the user's wallet accounts from a ZentraPay product.
     */
    @Transactional
    public TransactionModel creditInternal(TransactionModel draft, AccountsModel account, String narration, String notifyTitle, String notifyMessage) {
        BigDecimal newBalance = moveCredit(account.getId(), draft.getDestinationAmount(), draft.getDestinationCurrencyCode());
        String entryId = NanoIdGenerator.generate("ENT_", 21);
        draft.setEntryId(entryId);
        draft.setStatus(Datatypes.TransactionStatus.SUCCESS);
        TransactionModel txn = transactionsServices.save(draft);
        credit(txn.getId(), entryId + "_INTERNAL", account.getZentag(),
                draft.getDestinationAmount(), newBalance, draft.getDestinationCurrencyCode(), narration);
        notify(txn.getReceiverId(), txn, notifyTitle, notifyMessage);
        return txn;
    }

    /**
     * The user's wallet account in this currency (public so product services can find it).
     */
    public AccountsModel walletAccount(UUID userId, String currencyCode) {
        return accountFor(userId, currencyCode.toUpperCase());
    }

    // ==================================================================
    // Helpers
    // ==================================================================

    // Reads the transaction row with a database lock via TransactionsServices
    private TransactionModel lock(UUID transactionId) {
        return transactionsServices.getAndLockTransaction(transactionId);
    }

    // Locks an account row by ID via AccountsServices
    private AccountsModel lockAccountById(UUID accountId) {
        return accountsServices.getAndLockAccountForUpdate(accountId);
    }

    // Moves money out of an account via TransactionsServices and returns the updated balance
    private BigDecimal moveDebit(UUID accountId, BigDecimal amount, String currencyCode) {
        return accountsServices.debit(amount, currencyCode, accountId);
    }

    // Moves money into an account via TransactionsServices and returns the updated balance
    private BigDecimal moveCredit(UUID accountId, BigDecimal amount, String currencyCode) {
        return accountsServices.credit(amount, currencyCode, accountId);
    }

    // The sender's account in the currency that was debited
    private AccountsModel senderAccount(TransactionModel txn) {
        return accountFor(txn.getSenderId(), txn.getSourceCurrencyCode());
    }

    // The receiver's account in the currency that is credited
    private AccountsModel receiverAccount(TransactionModel txn) {
        return accountFor(txn.getReceiverId(), txn.getDestinationCurrencyCode());
    }

    // Resolves a user's currency account through AccountsServices
    private AccountsModel accountFor(UUID userId, String currencyCode) {
        if (userId == null) {
            throw new ResourceNotFoundException("User not found");
        }
        return accountsServices.getAccount(userId, currencyCode.toUpperCase(), null);
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

    // Generates a gateway reference from the persisted transaction ID
    private String gatewayReference(TransactionModel txn) {
        return "zp-" + txn.getId();
    }

    // Column limits are 255 (narration, failure reason) and 500 (notification message)
    private String truncate(String text) {
        if (text == null) {
            return null;
        }
        return text.length() > 250 ? text.substring(0, 250) : text;
    }
}