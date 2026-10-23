package com.zentrapay.backend.dto.schedules;

import java.util.List;

public record PaystackBankResponseDTO(
        Boolean status,
        String message,
        List<BankItemDTO> data
) {
    public record BankItemDTO(
            String name,
            String code,
            Boolean pay_with_bank,
            Boolean active,
            String country,
            String currency,
            String type
    ) {}
}