package com.zentrapay.backend.dto.user;

import jakarta.validation.constraints.NotBlank;

public record PinVerifyRequestDTO(
        @NotBlank(message = "PIN is required") String pin
) {
}
