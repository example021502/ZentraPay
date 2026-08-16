package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto;

import jakarta.validation.constraints.AssertFalse;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

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
        @NotBlank(message = "Password is required") String password,
        @NotBlank(message = "PIN is required") String pin,
        @NotBlank(message = "Zentag is required") String zentag
) {
}
