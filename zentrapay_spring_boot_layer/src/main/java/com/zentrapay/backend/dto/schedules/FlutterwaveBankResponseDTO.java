package com.zentrapay.backend.dto.schedules;

import java.util.List;

public record FlutterwaveBankResponseDTO(
        String status,
        String message,
        List<BankItemDTO> data
) {
    public record BankItemDTO(
            String id, // Flutterwave usually returns string IDs like "bnk_cYjd92Qk"
            String code,
            String name
    ) {}
}