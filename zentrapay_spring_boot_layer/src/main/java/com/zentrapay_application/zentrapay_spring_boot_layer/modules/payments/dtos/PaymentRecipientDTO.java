package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

public record PaymentRecipientDTO(
        String fullName,
        String email,
        String phoneNumber,
        String countryCode
) {
}
