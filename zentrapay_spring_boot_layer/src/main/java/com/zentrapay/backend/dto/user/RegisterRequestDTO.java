package com.zentrapay.backend.dto.user;

import jakarta.validation.constraints.*;

import java.util.UUID;

public record RegisterRequestDTO(
        @AssertTrue(message = "User consent to the terms of use is required") Boolean termsConsent,
//        UUID privacyPolicyId,
//        UUID termsOfUseId,
        @NotBlank(message = "First name is required") String firstName,
        @NotBlank(message = "Last name is required") String lastName,
        @Email(message = "Invalid email format") String email,
        @NotBlank(message = "Phone number is required") String phoneNumber,
        @NotBlank(message = "Country code is required") String countryCode,
        @NotBlank(message = "Password is required")
        @Size(min = 8, message = "password has to be at least 6 characters long.")
        String password,
        @NotBlank(message = "PIN is required") String pin
) {
}
