package com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.dto;

public record PayResponseDTO(
        PaymentSummaryDTO payment,
        TransactionDTO transaction
) {
}
