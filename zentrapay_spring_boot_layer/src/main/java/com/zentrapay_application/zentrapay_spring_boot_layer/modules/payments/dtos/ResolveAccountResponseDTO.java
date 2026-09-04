package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

/** GET /api/payment-channels/resolve response — the verified account holder's name. */
public record ResolveAccountResponseDTO(
        String accountName,
        String accountNumber
) {
}
