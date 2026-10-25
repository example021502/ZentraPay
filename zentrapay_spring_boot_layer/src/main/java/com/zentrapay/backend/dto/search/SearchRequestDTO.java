package com.zentrapay.backend.dto.search;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record SearchRequestDTO(
        @NotBlank(message = "Search query cannot be blank")
        String query,
        @Min(value = 0)
        @Max(value = 20, message = "Limit cannot exceed 20")
        int limit
) {
}