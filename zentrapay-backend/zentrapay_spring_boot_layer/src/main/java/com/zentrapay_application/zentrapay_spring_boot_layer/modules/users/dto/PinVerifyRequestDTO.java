package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto;

import jakarta.validation.constraints.NotBlank;

public record PinVerifyRequestDTO(
        @NotBlank(message = "PIN is required") String pin
) {
}
