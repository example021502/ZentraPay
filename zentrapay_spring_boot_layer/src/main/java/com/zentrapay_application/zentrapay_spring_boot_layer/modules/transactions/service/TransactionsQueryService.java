package com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.TransactionModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.TransactionRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.dtos.TransactionDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.dtos.TransactionPageDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Read side of the transactions ledger — API_CONTRACT.md §5. Every module
 * that moves money (payments, bill payments, savings, ...) writes to the
 * same {@code transactions} table; this just paginates it back out for the
 * authenticated user.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class TransactionsQueryService {

    private final TransactionRepository transactionRepository;

    public TransactionPageDTO getHistory(UUID userId, int page, int size) {
        int safeSize = size > 0 ? Math.min(size, 100) : 20;
        int safePage = Math.max(page, 0);
        Page<TransactionModel> result = transactionRepository.findUserHistory(
                userId, PageRequest.of(safePage, safeSize, Sort.by(Sort.Direction.DESC, "createdAt")));

        return new TransactionPageDTO(
                result.getContent().stream().map((txn)->_resolveTransactionDetails(txn, userId)).toList(),
                result.getNumber(),
                result.getSize(),
                result.getTotalElements(),
                result.getTotalPages()
        );
    }

    private TransactionDTO _resolveTransactionDetails(TransactionModel t, UUID userId) {
        return new TransactionDTO(
                t.getTransactionId(),
                t.getReceiverId(),
                // The client shows/quotes internalReferenceId as TXN_Ref.
                t.getInternalReferenceId(),
                t.getDestinationIdentifier(),
                _resolveSignedAmount(t, userId),
                t.getStatus(),
                t.getReceiverName(),
                // The client searches/filters rows by the counterparty phone.
                t.getReceiverPhoneNumber(),
                // The client's model reads completedAt (falling back to
                // createdAt); the ledger only tracks createdAt.
                t.getCreatedAt(),
                t.getTransactionType()
        );
    }

    /**
     * Builds the display amount the client expects: a leading "+" when the
     * authenticated user is the receiver (credit) or "-" when they are the
     * sender (debit), followed by the currency code and the plain amount —
     * e.g. "+GHS 100.00" / "-GHS 100.00". The sign is what drives the
     * client's green/red coloring, call_received/call_made icons and
     * "Send Again" visibility, and the currency code is folded into the
     * same string (there is no separate currencyCode field anymore).
     */
    private String _resolveSignedAmount(TransactionModel t, UUID userId) {
        boolean isCredit = t.getReceiverId() != null
                && userId.toString().equalsIgnoreCase(t.getReceiverId().toString());
        String sign = isCredit ? "+" : "-";
        // Credits arrive in the destination currency; debits leave in the
        // source currency (identical for wallet-to-wallet, differs for FX).
        String currencyCode = isCredit
                ? t.getDestinationCurrencyCode()
                : t.getSourceCurrencyCode();
        BigDecimal amount = t.getAmount();
        return sign + currencyCode + " " + (amount != null ? amount.toPlainString() : "0.00");
    }
}
