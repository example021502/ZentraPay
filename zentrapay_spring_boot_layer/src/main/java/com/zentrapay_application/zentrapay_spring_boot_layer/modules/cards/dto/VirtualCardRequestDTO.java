package com.zentrapay_application.zentrapay_spring_boot_layer.modules.cards.dto;

import jakarta.validation.constraints.NotBlank;

public record VirtualCardRequestDTO(
        @NotBlank(message = "Brand is required") String brand
) {
}
