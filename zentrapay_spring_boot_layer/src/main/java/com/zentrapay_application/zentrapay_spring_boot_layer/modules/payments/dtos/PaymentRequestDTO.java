package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;


public record PaymentRequestDTO(
        @NotBlank(message = "Transaction Id missing") String TransactionId,

        @NotBlank(message = "PIN missing") String pin,

        @NotNull(message = "recipient is required")
        PaymentRecipientDTO recipient,

        @NotNull(message = "destination is required")
        @Valid
        PaymentDestinationDTO destination,

        @NotNull(message = "Amount information is required")
        @Valid
        PaymentTransferDTO transfer
) {
}
