package com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.dto;

import java.util.UUID;

public record PaymentSummaryDTO(
        UUID paymentId,
        String status
) {
}
