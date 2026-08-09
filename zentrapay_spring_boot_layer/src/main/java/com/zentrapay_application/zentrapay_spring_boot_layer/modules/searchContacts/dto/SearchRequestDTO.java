package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record SearchRequestDTO(
        @NotNull(message = "User Error")
        UUID userId,

        @NotBlank(message = "Search query cannot be blank")
        String query,

        @Min(value = 0)
        @Max(value = 20, message = "Limit cannot exceed 20")
        int limit
) {
}