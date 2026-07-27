package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

import jakarta.validation.constraints.NotBlank;

public record RecipientDetailsDTO(
        @NotBlank(message = "Account name is missing") String accountName,
        @NotBlank(message = "Account number or phone number is missing") String accountNumber,
        @NotBlank(message = "Bank code or network provider code is missing") String bankCode,
        String bankName,
        @NotBlank(message = "Country code is missing") String countryCode,
        String email
) {
}