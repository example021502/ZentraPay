package com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ResourceNotFoundException;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.Transaction;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.TransactionRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.dto.PageResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.dto.TransactionResponseDTO;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Backs the generic {@code /api/transactions} feed (API contract §5) — a read-only
 * view over the canonical {@link Transaction} ledger written by PaymentsServices,
 * CardsServices, etc. Also absorbs the deleted {@code history} module's
 * {@code /api/history/paymentsHistory} — same data, one endpoint now.
 */
@Service
@Transactional(readOnly = true)
public class TransactionsService {

    private final TransactionRepository transactionRepository;

    public TransactionsService(TransactionRepository transactionRepository) {
        this.transactionRepository = transactionRepository;
    }

    /**
     * {@code type} and {@code status} filters are supported individually. The
     * canonical {@link TransactionRepository} (owned by the domain layer, not
     * this module) does not expose a combined type+status query, so if both are
     * supplied {@code type} takes precedence — a deliberate, documented limitation
     * rather than reaching into the shared repository to add a bespoke method.
     */
    public PageResponseDTO<TransactionResponseDTO> getUserTransactions(UUID userId, int page, int size, String type, String status) {
        Pageable pageable = PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), 100));

        Page<Transaction> result;
        if (type != null && !type.isBlank()) {
            result = transactionRepository.findByUserIdAndTypeCodeOrderByCreatedAtDesc(userId, type, pageable);
        } else if (status != null && !status.isBlank()) {
            result = transactionRepository.findByUserIdAndStatusOrderByCreatedAtDesc(userId, status, pageable);
        } else {
            result = transactionRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable);
        }

        return PageResponseDTO.from(result.map(TransactionResponseDTO::from));
    }

    public TransactionResponseDTO getUserTransaction(UUID userId, UUID transactionId) {
        Transaction transaction = transactionRepository.findByTransactionIdAndUserId(transactionId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Transaction not found"));
        return TransactionResponseDTO.from(transaction);
    }
}
