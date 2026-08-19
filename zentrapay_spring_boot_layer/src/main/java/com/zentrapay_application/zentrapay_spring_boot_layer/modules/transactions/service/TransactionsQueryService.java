package com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.Transaction;
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
        Page<Transaction> result = transactionRepository.findByUserIdOrderByCreatedAtDesc(
                userId, PageRequest.of(safePage, safeSize, Sort.by(Sort.Direction.DESC, "createdAt")));

        return new TransactionPageDTO(
                result.getContent().stream().map(this::toDTO).toList(),
                result.getNumber(),
                result.getSize(),
                result.getTotalElements(),
                result.getTotalPages()
        );
    }

    private boolean isCreditType(String typeCode) {
        return typeCode != null && typeCode.endsWith("_CREDIT");
    }

    private TransactionDTO toDTO(Transaction t) {
        String sign = isCreditType(t.getTypeCode()) ? "+" : "-";
        return new TransactionDTO(
                t.getTransactionId(),
                t.getTypeCode(),
                sign + t.getAmount().toPlainString(),
                t.getCurrencyCode(),
                t.getStatus(),
                t.getGateway(),
                t.getReference(),
                t.getCounterpartyName(),
                t.getCounterpartyIdentifier(),
                t.getDescription(),
                t.getCreatedAt()
        );
    }
}
