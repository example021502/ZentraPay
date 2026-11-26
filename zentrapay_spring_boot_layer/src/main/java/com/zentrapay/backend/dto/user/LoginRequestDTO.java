package com.zentrapay.backend.dto.user;

import jakarta.validation.constraints.NotBlank;

public record LoginRequestDTO(
        String email,
        String phoneNumber,
        @NotBlank(message = "Password is required") String password
) {
    public LoginRequestDTO {
        if (email().isBlank() && phoneNumber().isBlank()) {
            throw new RuntimeException("Either email or phone number is required to continue.");
        }
    }
}

