package com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.dto;

public record ValidateResponseDTO(
        boolean valid,
        String customerName
) {
}
