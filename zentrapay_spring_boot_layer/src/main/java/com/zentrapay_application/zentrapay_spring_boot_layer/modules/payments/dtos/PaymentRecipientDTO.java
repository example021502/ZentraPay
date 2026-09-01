package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record PaymentRecipientDTO(
        @NotNull(message = "Receiver Name is required")
        String fullName,
        @NotNull(message = "Receiver Email is required")
        String email,
        @NotNull(message = "Receiver Phone number is required")
        String phoneNumber,
        @NotNull(message = "Receiver Country is required")
        @Size(max = 3, message = "Invalid country code")
        String countryCode
) {
}
