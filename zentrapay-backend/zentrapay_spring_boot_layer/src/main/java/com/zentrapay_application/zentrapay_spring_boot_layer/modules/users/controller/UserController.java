package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;
<<<<<<< HEAD
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.service.UsersService;
=======
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.AuthResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.RegisterRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.LoginRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.service.JwtService;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.service.UserService;
>>>>>>> update
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
<<<<<<< HEAD
=======
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.model.User;
>>>>>>> update


@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {
<<<<<<< HEAD
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
=======
    private final UserService userService;
    private final JwtService jwtService;

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<AuthResponse>> register(@RequestBody @Valid RegisterRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(userService.register(request), "Registered"));
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(@RequestBody @Valid LoginRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(userService.login(request), "Logged in"));
>>>>>>> update
    }
}