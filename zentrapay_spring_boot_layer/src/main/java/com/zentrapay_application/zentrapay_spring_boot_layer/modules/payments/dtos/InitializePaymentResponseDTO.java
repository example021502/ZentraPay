package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dto.TransferDataDTO;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Response for POST /api/payments/initialize — everything the Flutter client
 * needs to hand the payer off to the gateway's hosted checkout page.
 */
public record InitializePaymentResponseDTO(
        Boolean success,
        String message,
        TransferDataDTO data
) {
}