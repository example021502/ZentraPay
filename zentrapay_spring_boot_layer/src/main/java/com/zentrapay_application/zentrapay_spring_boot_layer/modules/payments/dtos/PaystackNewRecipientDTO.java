package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import jakarta.validation.constraints.NotNull;

public record PaystackNewRecipientDTO(
        @NotNull(message = "Recipient type missing")
        String type,
        @NotNull(message = "Recipient name missing")
        String name,
        @NotNull(message = "Recipient account number missing")
        String accountNumber,
        @NotNull(message = "Recipient Bank code missing")
        String bankCode,
        @NotNull(message = "Destination currency missing")
        String currency

) {
}
