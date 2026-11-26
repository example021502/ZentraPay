package com.zentrapay.backend.dto.user;

import jakarta.validation.constraints.*;

public record RegisterRequestDTO(
        @AssertTrue(message = "Please read, understand and accept our terms or privacy policy to continue") Boolean termsConsent,
        @NotBlank(message = "First name is required") String firstName,
        @NotBlank(message = "Last name is required") String lastName,
        @NotBlank(message = "Email is required") @Email(message = "Invalid email format") String email,
        @NotBlank(message = "Phone number is required") String phoneNumber,
        @NotBlank(message = "Country code is required") String countryCode,
        // Same rules as change / reset password (CredentialService), so a user is never
        // allowed to register with a password they could not later set
        @NotBlank(message = "Password is required")
        @Size(min = 8, max = 32, message = "Your password must be 8 to 32 characters long")
        String password,
        @NotBlank(message = "PIN is required")
        @Pattern(regexp = "\\d{4}", message = "Your PIN must be exactly 4 digits")
        String pin
) {
    /**
     * Never print the password or PIN: a record's default toString would put both in the logs.
     */
    @Override
    public String toString() {
        return "RegisterRequestDTO[email=" + email + ", phoneNumber=" + phoneNumber + ", countryCode=" + countryCode + "]";
    }
}
