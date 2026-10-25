package com.zentrapay.backend.dto.user;

import jakarta.validation.constraints.NotBlank;

/** Request / response shapes of the change / forgot / reset password and PIN endpoints. */
public final class CredentialDTOs {

    private CredentialDTOs() {
    }

    public record ChangePasswordRequestDTO(
            @NotBlank(message = "Your current password is required") String currentPassword,
            @NotBlank(message = "A new password is required") String newPassword
    ) {
    }

    public record ChangePinRequestDTO(
            @NotBlank(message = "Your current PIN is required") String currentPin,
            @NotBlank(message = "A new PIN is required") String newPin
    ) {
    }

    /** The code that was emailed to the user. */
    public record VerifyResetCodeRequestDTO(
            @NotBlank(message = "Paste the code from your email") String code
    ) {
    }

    public record ResetPasswordRequestDTO(
            @NotBlank(message = "Reset token is required") String resetToken,
            @NotBlank(message = "A new password is required") String newPassword
    ) {
    }

    public record ResetPinRequestDTO(
            @NotBlank(message = "Reset token is required") String resetToken,
            @NotBlank(message = "A new PIN is required") String newPin
    ) {
    }

    /** Answer to "forgot": where the email went and how long the code lives. */
    public record ResetRequestedDTO(String emailHint, int expiresInMinutes) {
    }

    /** Answer to a correct code: the short-lived token that opens the "new password / PIN" step. */
    public record ResetTokenDTO(String resetToken, int expiresInMinutes) {
    }
}
