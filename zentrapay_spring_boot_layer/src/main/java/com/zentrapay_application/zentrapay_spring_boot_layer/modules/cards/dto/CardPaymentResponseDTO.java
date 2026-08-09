package com.zentrapay_application.zentrapay_spring_boot_layer.modules.cards.dto;

import java.util.UUID;

public record CardPaymentResponseDTO(
        UUID transactionId,
        String status
) {
}
