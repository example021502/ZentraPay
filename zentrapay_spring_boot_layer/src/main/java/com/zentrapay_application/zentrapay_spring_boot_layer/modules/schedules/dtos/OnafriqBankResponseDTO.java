package com.zentrapay_application.zentrapay_spring_boot_layer.modules.schedules.dtos;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

public record OnafriqBankResponseDTO(
        String status,
        String message,
        @JsonProperty("data") List<BankItemDTO> results
) {
    public record BankItemDTO(
            String bankName,
            String bank_code,
            String bic,
            String currencyCode,
            String iban,
            String maxDailyValue,
            String maxMonthlyValue,
            String maxPerTxLimit,
            String maxWeeklyValue,
            String minPerTxLimit
    ) {}
}