package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;


public record GatewayCreateCustomerDTO(
        String email,
        String firstName,
        String lastName,
        String phoneNumber
) {
}
