package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.service.UsersService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;


@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {
    private final UsersService userService;

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<usersAuthResponse>> register(@RequestBody @Valid RegisterRequestDTO request) {
        System.out.println("[SPRING_CTRL] register hit by " + request);
        usersAuthResponse userData = userService.register(request);
        return ResponseEntity.ok(ApiResponse.success(userData, "Registered"));
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<usersAuthResponse>> login(@RequestBody @Valid LoginRequestDTO request) {
        System.out.println("[SPRING_CTRL] login hit by " + request);
        usersAuthResponse userData = userService.login(request);
        return ResponseEntity.ok(ApiResponse.success(userData, "Logged in"));
    }

    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<usersAuthResponse>> refresh(@RequestHeader("Authorization") String authorization) {
        String token = authorization.startsWith("Bearer ") ? authorization.substring(7) : authorization;
        usersAuthResponse userData = userService.refresh(token);
        return ResponseEntity.ok(ApiResponse.success(userData, "Token refreshed"));
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserProfileDTO>> me(Authentication authentication) {
        UUID userId = UUID.fromString(authentication.getName());
        UserProfileDTO profile = userService.getProfile(userId);
        return ResponseEntity.ok(ApiResponse.success(profile, "Profile retrieved"));
    }

    @PostMapping("/pin/verify")
    public ResponseEntity<ApiResponse<PinVerifyResponseDTO>> verifyPin(Authentication authentication, @RequestBody @Valid PinVerifyRequestDTO request) {
        UUID userId = UUID.fromString(authentication.getName());
        PinVerifyResponseDTO result = userService.verifyPin(userId, request.pin());
        return ResponseEntity.ok(ApiResponse.success(result, "PIN verification completed"));
    }
}