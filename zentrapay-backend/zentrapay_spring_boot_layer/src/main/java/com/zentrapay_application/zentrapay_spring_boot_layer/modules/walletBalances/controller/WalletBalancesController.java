package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.service.UsersService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;


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
}