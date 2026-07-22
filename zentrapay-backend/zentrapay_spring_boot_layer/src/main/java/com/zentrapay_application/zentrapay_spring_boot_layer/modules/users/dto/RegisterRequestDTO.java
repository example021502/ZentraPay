package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record RegisterRequestDTO(
        @NotBlank(message = "Full name is required") String fullName,
        @Email(message = "Invalid email format") String email,
        @NotBlank(message = "Phone number is required") String phoneNumber,
        @NotBlank(message = "Password is required") String password,
<<<<<<< HEAD
        String zentag,
=======
>>>>>>> update
        @NotBlank(message = "PIN is required") String pin,
        String country
) {}