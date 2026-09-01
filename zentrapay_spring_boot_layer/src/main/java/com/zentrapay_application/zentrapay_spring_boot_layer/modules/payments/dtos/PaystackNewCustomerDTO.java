package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import jakarta.validation.constraints.NotNull;

public record PaystackNewCustomerDTO(
        @NotNull(message = "Customer first name is required")
        String firstName,
        @NotNull(message = "Customer last name is required")
        String lastName,
        @NotNull(message = "Receiver Email is required")
        String email,
        @NotNull(message = "Receiver Phone number is required")
        String phoneNumber
) {
}
