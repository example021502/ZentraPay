package com.zentrapay.backend.dto.payment;

/** GET /api/payment-channels/resolve response — the verified account holder's name. */
public record ResolveAccountResponseDTO(
        String accountName,
        String accountNumber
) {
}
