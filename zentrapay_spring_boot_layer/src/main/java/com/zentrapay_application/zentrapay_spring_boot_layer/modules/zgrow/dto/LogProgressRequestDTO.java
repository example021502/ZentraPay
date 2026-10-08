package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.util.UUID;

// Payload sent when contributing funds towards a challenge
public record LogProgressRequestDTO(
        @NotNull(message = "Amount contributed is required")
        @DecimalMin(value = "0.01", message = "Contribution must be at least 0.01")
        BigDecimal amount,

        UUID transactionReference,
        String notes
) {}
