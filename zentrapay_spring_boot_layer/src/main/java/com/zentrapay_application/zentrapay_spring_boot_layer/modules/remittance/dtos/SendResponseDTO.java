package com.zentrapay_application.zentrapay_spring_boot_layer.modules.remittance.dtos;

public record SendResponseDTO(
        RemittanceSummaryDTO remittance,
        TransactionDTO transaction
) {
}
