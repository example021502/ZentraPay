package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.TransactionModel;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;

/**
 * Local mirror of the API_CONTRACT.md §5 {@code Transaction} response shape,
 * built from {@link TransactionModel}.
 * Kept local to this module rather than importing another module's copy —
 * see billProviders.dto.TransactionDTO, which documents the same choice.
 * <p>
 * {@code amount} is a sign-prefixed string ("+12.50" / "-12.50"), matching
 * the frontend's {@code AppTransaction}/{@code AmountText} contract, which
 * colors an amount by whether its string starts with '+'.
 */
public record PaymentRecipientDTO(
        @NotBlank(message = "Recipient Name required")
        @Valid
        String fullName,

        @NotBlank(message = "Recipient Email required")
        @Valid
        String email,

        @NotBlank(message = "Recipient Phone number required")
        @Valid
        String phoneNumber,

        @NotBlank(message = "Recipient Type required")
        @Valid
        String userType

) {
}
