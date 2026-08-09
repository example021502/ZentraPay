package com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.dto;

import org.springframework.data.domain.Page;

import java.util.List;

/**
 * Pagination envelope exactly matching API contract §5:
 * {@code {content:[Transaction], page,size,totalElements,totalPages}}.
 * <p>
 * Spring Data's default {@link Page} JSON serialization includes many extra
 * fields (pageable, sort, ...) not in the contract, so this flattens it down.
 */
public record PageResponseDTO<T>(
        List<T> content,
        int page,
        int size,
        long totalElements,
        int totalPages
) {
    public static <T> PageResponseDTO<T> from(Page<T> page) {
        return new PageResponseDTO<>(
                page.getContent(),
                page.getNumber(),
                page.getSize(),
                page.getTotalElements(),
                page.getTotalPages()
        );
    }
}
