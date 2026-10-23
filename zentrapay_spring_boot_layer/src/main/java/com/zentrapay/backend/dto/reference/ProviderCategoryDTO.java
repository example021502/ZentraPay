package com.zentrapay.backend.dto.reference;

/**
 * Provider-category row for {@code GET /api/reference/provider-categories} —
 * API_CONTRACT.md §2: {@code {categoryCode,categoryName}}.
 */
public record ProviderCategoryDTO(
        String categoryCode,
        String categoryName
) {
}
