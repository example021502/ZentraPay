package com.zentrapay.backend.controller;

import com.zentrapay.backend.dto.common.ApiResponse;
import com.zentrapay.backend.dto.user.CredentialDTOs.*;
import com.zentrapay.backend.security.AuthenticatedUser;
import com.zentrapay.backend.security.CurrentUser;
import com.zentrapay.backend.service.user.CredentialService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Change and recover the password / transaction PIN (signed-in users only).
 * <pre>
 * POST /api/users/password/change        {currentPassword, newPassword}
 * POST /api/users/password/forgot        emails a one-time code
 * POST /api/users/password/verify-code   {code} -> {resetToken}
 * POST /api/users/password/reset         {resetToken, newPassword}
 * POST /api/users/pin/change             {currentPin, newPin}
 * POST /api/users/pin/forgot             emails a one-time code
 * POST /api/users/pin/verify-code        {code} -> {resetToken}
 * POST /api/users/pin/reset              {resetToken, newPin}
 * </pre>
 */
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class CredentialController {

    private final CredentialService credentialService;

    // ---- password ----

    @PostMapping("/password/change")
    public ResponseEntity<ApiResponse<Void>> changePassword(
            @CurrentUser AuthenticatedUser user, @Valid @RequestBody ChangePasswordRequestDTO request) {
        credentialService.changePassword(user.getUserId(), request.currentPassword(), request.newPassword());
        return ResponseEntity.ok(ApiResponse.success("Password changed"));
    }

    @PostMapping("/password/forgot")
    public ResponseEntity<ApiResponse<ResetRequestedDTO>> forgotPassword(@CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(
                credentialService.requestReset(user.getUserId(), CredentialService.PASSWORD), "We emailed you a code"));
    }

    @PostMapping("/password/verify-code")
    public ResponseEntity<ApiResponse<ResetTokenDTO>> verifyPasswordCode(
            @CurrentUser AuthenticatedUser user, @Valid @RequestBody VerifyResetCodeRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(
                credentialService.verifyCode(user.getUserId(), CredentialService.PASSWORD, request.code()), "Code confirmed"));
    }

    @PostMapping("/password/reset")
    public ResponseEntity<ApiResponse<Void>> resetPassword(
            @CurrentUser AuthenticatedUser user, @Valid @RequestBody ResetPasswordRequestDTO request) {
        credentialService.resetPassword(user.getUserId(), request.resetToken(), request.newPassword());
        return ResponseEntity.ok(ApiResponse.success("Password reset"));
    }

    // ---- transaction PIN ----

    @PostMapping("/pin/change")
    public ResponseEntity<ApiResponse<Void>> changePin(
            @CurrentUser AuthenticatedUser user, @Valid @RequestBody ChangePinRequestDTO request) {
        credentialService.changePin(user.getUserId(), request.currentPin(), request.newPin());
        return ResponseEntity.ok(ApiResponse.success("PIN changed"));
    }

    @PostMapping("/pin/forgot")
    public ResponseEntity<ApiResponse<ResetRequestedDTO>> forgotPin(@CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(
                credentialService.requestReset(user.getUserId(), CredentialService.PIN), "We emailed you a code"));
    }

    @PostMapping("/pin/verify-code")
    public ResponseEntity<ApiResponse<ResetTokenDTO>> verifyPinCode(
            @CurrentUser AuthenticatedUser user, @Valid @RequestBody VerifyResetCodeRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(
                credentialService.verifyCode(user.getUserId(), CredentialService.PIN, request.code()), "Code confirmed"));
    }

    @PostMapping("/pin/reset")
    public ResponseEntity<ApiResponse<Void>> resetPin(
            @CurrentUser AuthenticatedUser user, @Valid @RequestBody ResetPinRequestDTO request) {
        credentialService.resetPin(user.getUserId(), request.resetToken(), request.newPin());
        return ResponseEntity.ok(ApiResponse.success("PIN reset"));
    }
}
