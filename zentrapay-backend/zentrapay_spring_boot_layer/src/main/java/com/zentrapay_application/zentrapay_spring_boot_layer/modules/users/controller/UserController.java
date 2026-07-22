package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.AuthResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.RegisterRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.LoginRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.service.JwtService;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.model.User;


@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {
    private final UserService userService;
    private final JwtService jwtService;

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<AuthResponse>> register(@RequestBody @Valid RegisterRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(userService.register(request), "Registered"));
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(@RequestBody @Valid LoginRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(userService.login(request), "Logged in"));
    }
}