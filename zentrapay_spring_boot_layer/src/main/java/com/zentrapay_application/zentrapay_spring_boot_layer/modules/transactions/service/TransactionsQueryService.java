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
        Page<TransactionModel> result = transactionRepository.findBySenderIdOrderByCreatedAtDesc(
                userId, PageRequest.of(safePage, safeSize, Sort.by(Sort.Direction.DESC, "createdAt")));

        return new TransactionPageDTO(
                result.getContent().stream().map(this::toDTO).toList(),
                result.getNumber(),
                result.getSize(),
                result.getTotalElements(),
                result.getTotalPages()
        );
    }


    private TransactionDTO toDTO(TransactionModel t) {
        String sign = t.getTransactionType().equalsIgnoreCase("credit") ? "+" : "-";
        // Map TransactionModel onto the TransactionDTO mirror (same field order)
        return new TransactionDTO(
                sign,
                t.getTransactionId(),
                t.getInternalReferenceId(),
                t.getExternalReferenceId(),
                t.getSenderId(),
                t.getReceiverId(),
                t.getSenderName(),
                t.getReceiverName(),
                t.getAmount(),
                t.getSourceCurrencyCode(),
                t.getDestinationCurrencyCode(),
                t.getPurpose(),
                t.getFailureReason(),
                t.getGateway(),
                t.getMetadata(),
                t.getStatus(),
                t.getTransactionType(),
                t.getSenderEmail(),
                t.getSenderPhoneNumber(),
                t.getReceiverEmail(),
                t.getReceiverPhoneNumber(),
                t.getCreatedAt(),
                t.getUpdatedAt()
        );
    }
}
