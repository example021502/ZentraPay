package com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.dto;

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
