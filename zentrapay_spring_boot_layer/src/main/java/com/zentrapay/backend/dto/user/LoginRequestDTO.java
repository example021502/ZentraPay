package com.zentrapay.backend.dto.user;

import jakarta.validation.constraints.NotBlank;

public record LoginRequestDTO(
        String email,
        String phoneNumber,
        @NotBlank(message = "Password is required") String password
) {}

