package com.zentrapay_application.zentrapay_spring_boot_layer.modules.schedules.dtos;

import java.util.List;

public record PaystackBankResponseDTO(
        boolean status,
        String message,
        List<BankItemDTO> data
) {
    public record BankItemDTO(
            String name,
            String code,
            boolean pay_with_bank,
            boolean active,
            String country,
            String currency
    ) {}
}