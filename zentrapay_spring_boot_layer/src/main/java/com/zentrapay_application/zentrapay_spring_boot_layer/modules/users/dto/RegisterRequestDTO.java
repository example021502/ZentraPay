package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record RegisterRequestDTO(
        @NotBlank(message = "First name is required") String firstName,
        @NotBlank(message = "Last name is required") String lastName,
        @Email(message = "Invalid email format") String email,
        @NotBlank(message = "Phone number is required") String phoneNumber,
        @NotBlank(message = "Country code is required") String countryCode,
        @NotBlank(message = "Password is required") String password,
        @NotBlank(message = "PIN is required") String pin,
        @NotBlank(message = "Zentag is required") String zentag
) {
}
