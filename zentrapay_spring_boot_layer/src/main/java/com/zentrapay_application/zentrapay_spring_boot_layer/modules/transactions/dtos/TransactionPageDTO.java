package com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.dtos;

import java.util.List;

/**
 * Matches the frontend's {@code TransactionPage.fromJson} shape exactly:
 * {content, page, size, totalElements, totalPages}.
 */
public record TransactionPageDTO(
        List<TransactionDTO> content,
        int page,
        int size,
        long totalElements,
        int totalPages
) {
}
