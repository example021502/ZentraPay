package com.zentrapay.backend.dto.bank;

import jakarta.validation.constraints.NotBlank;

import java.util.UUID;

/**
 * Request body for {@code POST /api/zbanking/link} — matches the frontend
 * link-a-bank sheet payload.
 */
public record LinkNewBankRequestDTO(
        @NotBlank(message = "Target bank is required") String bankId,
        @NotBlank(message = "Target account number is required") String accountNumber,
        /** Optional display label; when absent the catalog bank name is used. */
        String linkLabel,
        /** When true the newly linked bank becomes the primary account. */
        Boolean primary
) {
}
