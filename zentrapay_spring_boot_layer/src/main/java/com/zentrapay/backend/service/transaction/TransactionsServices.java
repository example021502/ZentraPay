package com.zentrapay.backend.service.transaction;

import com.zentrapay.backend.entity.TransactionModel;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.repository.TransactionRepository;
import com.zentrapay.backend.dto.transaction.TransactionDTO;
import com.zentrapay.backend.dto.transaction.TransactionPageDTO;
import com.zentrapay.backend.service.common.Datatypes;
import com.zentrapay.backend.service.common.Utils;
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
public class TransactionsServices {

    private final TransactionRepository transactionRepository;

    public TransactionPageDTO getHistory(UUID userId, int page, int size) {
        int safeSize = size > 0 ? Math.min(size, 100) : 20;
        int safePage = Math.max(page, 0);
        Page<TransactionModel> result = transactionRepository.findUserHistory(
                userId, PageRequest.of(safePage, safeSize, Sort.by(Sort.Direction.DESC, "createdAt")));

        return new TransactionPageDTO(
                result.getContent().stream().map(txn -> toDto(txn, userId)).toList(),
                result.getNumber(),
                result.getSize(),
                result.getTotalElements(),
                result.getTotalPages()
        );
    }

    /**
     * One transaction as the app shows it. Also used as the response of a payment,
     * so the payment result and the history row always have the same shape.
     */
    public TransactionDTO toDto(TransactionModel t, UUID userId) {
        // On money coming IN the "other party" is the sender, not the user themselves
        boolean credit = Utils.isCredit(t.getReceiverId(), userId);
        return new TransactionDTO(
                t.getId(),
                t.getReceiverId(),
                // The client shows/quotes internalReferenceId as TXN_Ref.
                t.getInternalReferenceId(),
                t.getDestinationIdentifier(),
                Utils.getSignedAmount(t.getReceiverId(), userId, t.getSourceCurrencyCode(), t.getDestinationCurrencyCode(), t.getDestinationAmount(), t.getAmount()),
                t.getStatus(),
                credit && t.getSenderName() != null ? t.getSenderName() : t.getReceiverName(),
                // The client searches/filters rows by the counterparty phone.
                credit && t.getSenderPhoneNumber() != null ? t.getSenderPhoneNumber() : t.getReceiverPhoneNumber(),
                // The client's model reads completedAt (falling back to
                // createdAt); the ledger only tracks createdAt.
                t.getCreatedAt(),
                t.getTransactionType(),
                t.getFailureReason(),
                t.getPurpose()
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

    // saving transactions
    public TransactionModel save(TransactionModel t) {
        return transactionRepository.save(t);
    }

    public TransactionModel getByIdempotencyKey(String key) {
        return transactionRepository.getTransactionByIdempotencyKey(key)
                .orElseThrow(() -> new RuntimeException("Transaction not found."));
    }

    public TransactionDTO getTransactionByIdempotencyKeyAndSenderId(String key, UUID userId) {
        return transactionRepository.getByIdempotencyKeyAndSenderId(key, userId)
                .map(t -> new TransactionDTO(
                        t.getId(),
                        t.getReceiverId(),
                        t.getInternalReferenceId(),
                        t.getDestinationIdentifier(),
                        Utils.getSignedAmount(t.getReceiverId(), userId, t.getSourceCurrencyCode(), t.getDestinationCurrencyCode(), t.getDestinationAmount(), t.getAmount()),
                        t.getStatus(),
                        t.getReceiverName(),
                        getReceiverIdentifier(t.getReceiverEmail(), t.getReceiverPhoneNumber()),
                        t.getCreatedAt(),
                        t.getTransactionType(),
                        t.getFailureReason(),
                        t.getPurpose()
                ))
                .orElseThrow(() -> new ResourceNotFoundException("Transaction not found."));
    }

    private String getReceiverIdentifier(String receiverEmail, String receiverPhoneNumber) {
        if (!receiverPhoneNumber.isBlank()) {
            return receiverPhoneNumber;
        }
        if (!receiverEmail.isBlank()) {
            return receiverEmail;
        }
        return null;
    }

    @Transactional
    public TransactionModel addNew(
            String idempotencyKey,
            BigDecimal sourceAmount,
            String sourceCurrencyCode,
            String destinationCurrencyCode,
            BigDecimal destinationAmount,
            String purpose,
            UUID senderId,
            String senderName,
            String senderEmail,
            String senderPhoneNumber,
            String destinationIdentifier,
            String receiverName,
            UUID receiverId
    ) {
        TransactionModel t = new TransactionModel();
        t.setInternalReferenceId(Utils.getRandomId("ZENREF_"));
        t.setTransactionType(Datatypes.TransactionType.BILL_PAYMENT);
        t.setIdempotencyKey(idempotencyKey);
        t.setEntryId(Utils.getEntryId());
        t.setAmount(sourceAmount);
        t.setSourceCurrencyCode(sourceCurrencyCode);
        t.setDestinationCurrencyCode(destinationCurrencyCode);
        t.setDestinationAmount(destinationAmount);
        t.setPurpose(purpose);
        t.setSenderId(senderId);
        t.setSenderName(senderName);
        t.setSenderEmail(senderEmail);
        t.setSenderPhoneNumber(senderPhoneNumber);
        t.setDestinationIdentifier(destinationIdentifier);
        t.setReceiverId(receiverId);
        t.setReceiverName(receiverName);

        return transactionRepository.save(t);
    }

    @Transactional
    public TransactionModel getAndLockTransaction(UUID transactionId) {
        return transactionRepository.findByIdForUpdate(transactionId)
                .orElseThrow(() -> new RuntimeException("Transaction not found."));
    }
}
