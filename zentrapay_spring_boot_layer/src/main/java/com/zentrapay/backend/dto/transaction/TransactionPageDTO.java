package com.zentrapay.backend.dto.transaction;

import java.util.List;

/**
 * Matches the frontend's {@code TransactionPage.fromJson} shape exactly:
 * {content, page, size, totalElements, totalPages}.
 */
public record TransactionPageDTO(
        List<TransactionTransactionDTO> content,
        int page,
        int size,
        long totalElements,
        int totalPages
) {
}
