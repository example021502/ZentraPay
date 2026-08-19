package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.Map;

/**
 * POST /api/payments body. Shape is deliberately flat: pin, sender,
 * recipient, destination.
 * <p>
 * {@code sender} and {@code recipient} are accepted as loose maps — they're
 * exactly what the frontend already has in hand from search-contacts
 * (SenderDetails / the selected SearchAppUser), echoed back for the
 * confirmation UI and for logging, not re-parsed into typed fields here.
 * They are NOT the source of truth for whose money moves: the sender is
 * always the JWT-authenticated caller (never trust a client-supplied sender
 * id for that), and the recipient is derived from {@code destination}'s
 * account, not from {@code recipient}'s fields.
 */
public record PaymentRequestDTO(
        @NotBlank(message = "PIN is required")
        String pin,

        @NotNull(message = "Receiver Information is required")
        @Valid
        PaymentRecipientDTO recipient,

        @NotNull(message = "Destination Information is required")
        @Valid
        PaymentDestinationDTO destination,

        @NotNull(message = "Amount information is required")
        @Valid
        PaymentTransferDTO transfer


) {
}
