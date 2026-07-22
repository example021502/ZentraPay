package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto;

import jakarta.validation.constraints.NotBlank;

public record LoginRequestDTO(
        String email,
        String phoneNumber,
        @NotBlank(message = "Password is required") String password
) {}
