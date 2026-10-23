package com.zentrapay.backend.dto.bill;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record ValidateRequestDTO(
        @NotNull(message = "providerId is required")
        UUID providerId,

        @NotBlank(message = "customerReference is required")
        String customerReference
) {
}
