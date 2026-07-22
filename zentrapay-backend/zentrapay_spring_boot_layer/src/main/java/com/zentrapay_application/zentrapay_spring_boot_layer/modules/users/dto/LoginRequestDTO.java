package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto;

import jakarta.validation.constraints.NotBlank;

public record LoginRequestDTO(
        String email,
        @NotBlank(message = "Phone") String phoneNumber,
        @NotBlank(message = "Password is required") String password
) {}