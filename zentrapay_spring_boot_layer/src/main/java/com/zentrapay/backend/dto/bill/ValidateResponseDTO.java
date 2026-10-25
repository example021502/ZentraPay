package com.zentrapay.backend.dto.bill;

public record ValidateResponseDTO(
        boolean valid,
        String customerName
) {
}
