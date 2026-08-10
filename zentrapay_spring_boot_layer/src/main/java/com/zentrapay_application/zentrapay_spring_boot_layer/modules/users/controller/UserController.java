package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.service.UsersService;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.AuthenticatedUser;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.CurrentUser;
import jakarta.servlet.http.HttpServletRequest;
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
        usersAuthResponse userData = userService.register(request);
        return ResponseEntity.ok(ApiResponse.success(userData, "Registered"));
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<usersAuthResponse>> login(@RequestBody @Valid LoginRequestDTO request,
                                                                  HttpServletRequest httpRequest) {
        usersAuthResponse userData = userService.login(request, httpRequest);
        return ResponseEntity.ok(ApiResponse.success(userData, "Logged in"));
    }

    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<usersAuthResponse>> refresh(@RequestHeader("Authorization") String authorization) {
        String token = authorization.startsWith("Bearer ") ? authorization.substring(7) : authorization;
        usersAuthResponse userData = userService.refresh(token);
        return ResponseEntity.ok(ApiResponse.success(userData, "Token refreshed"));
    }

    @PostMapping("/pin/verify")
    public ResponseEntity<ApiResponse<PinVerifyResponseDTO>> verifyPin(@CurrentUser AuthenticatedUser user,
                                                                         @RequestBody @Valid PinVerifyRequestDTO request) {
        PinVerifyResponseDTO result = userService.verifyPin(user.userId(), request.pin());
        return ResponseEntity.ok(ApiResponse.success(result, "PIN verification completed"));
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserProfileDTO>> me(@CurrentUser AuthenticatedUser user) {
        UserProfileDTO profile = userService.getMe(user.userId());
        return ResponseEntity.ok(ApiResponse.success(profile, "Profile retrieved"));
    }

    @PatchMapping("/me")
    public ResponseEntity<ApiResponse<UserProfileDTO>> updateMe(@CurrentUser AuthenticatedUser user,
                                                                  @RequestBody UserMeUpdateDTO request) {
        UserProfileDTO profile = userService.updateMe(user.userId(), request);
        return ResponseEntity.ok(ApiResponse.success(profile, "Profile updated"));
    }

    @GetMapping("/me/profile")
    public ResponseEntity<ApiResponse<UserProfileDetailsDTO>> getKycProfile(@CurrentUser AuthenticatedUser user) {
        UserProfileDetailsDTO profile = userService.getKycProfile(user.userId());
        return ResponseEntity.ok(ApiResponse.success(profile, "KYC profile retrieved"));
    }

    @PutMapping("/me/profile")
    public ResponseEntity<ApiResponse<UserProfileDetailsDTO>> upsertKycProfile(@CurrentUser AuthenticatedUser user,
                                                                                 @RequestBody UserProfileDetailsDTO request) {
        UserProfileDetailsDTO profile = userService.upsertKycProfile(user.userId(), request);
        return ResponseEntity.ok(ApiResponse.success(profile, "KYC profile updated"));
    }

    @GetMapping("/me/receive")
    public ResponseEntity<ApiResponse<ReceiveInfoDTO>> getReceiveInfo(@CurrentUser AuthenticatedUser user) {
        ReceiveInfoDTO info = userService.getReceiveInfo(user.userId());
        return ResponseEntity.ok(ApiResponse.success(info, "Receive info retrieved"));
    }

    @GetMapping("/me/merchant-profile")
    public ResponseEntity<ApiResponse<MerchantProfileDTO>> getMerchantProfile(@CurrentUser AuthenticatedUser user) {
        MerchantProfileDTO profile = userService.getMerchantProfile(user.userId());
        return ResponseEntity.ok(ApiResponse.success(profile, "Merchant profile retrieved"));
    }

    @PutMapping("/me/merchant-profile")
    public ResponseEntity<ApiResponse<MerchantProfileDTO>> upsertMerchantProfile(@CurrentUser AuthenticatedUser user,
                                                                                   @RequestBody MerchantProfileDTO request) {
        MerchantProfileDTO profile = userService.upsertMerchantProfile(user.userId(), request);
        return ResponseEntity.ok(ApiResponse.success(profile, "Merchant profile updated"));
    }
}
