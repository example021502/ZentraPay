package com.zentrapay_application.zentrapay_spring_boot_layer.modules.reference.dto;

/**
 * Provider-category row for {@code GET /api/reference/provider-categories} —
 * API_CONTRACT.md §2: {@code {categoryCode,categoryName}}.
 */
public record ProviderCategoryDTO(
        String categoryCode,
        String categoryName
) {
}
