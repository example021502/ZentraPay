package com.zentrapay.backend.controller;

import com.zentrapay.backend.dto.user.requests.UserProfileUpdateRequest;
import com.zentrapay.backend.dto.common.ApiResponse;
import com.zentrapay.backend.dto.user.*;
import com.zentrapay.backend.service.user.UsersService;
import com.zentrapay.backend.security.AuthenticatedUser;
import com.zentrapay.backend.security.CurrentUser;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.jspecify.annotations.NonNull;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {
    private static final Logger log = LoggerFactory.getLogger(UserController.class);
    // Comment: Injected users service dependency
    private final UsersService userService;

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<usersAuthResponse>> register(
            @RequestBody @Valid RegisterRequestDTO request,
            HttpServletRequest req) {

        // Comment: Register user and pass the captured IP address for consent tracking
        usersAuthResponse userData = userService.register(request, req);

        return ResponseEntity.ok(ApiResponse.success(userData, "Registered"));
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<usersAuthResponse>> login(
            @RequestBody @Valid LoginRequestDTO request,
            HttpServletRequest httpRequest) {

        // Comment: Authenticate user login
        usersAuthResponse userData = userService.login(request, httpRequest);

        return ResponseEntity.ok(ApiResponse.success(userData, "Logged in"));
    }

    // Comment: Utility method to resolve client IP considering proxies and load balancers
    private String getClientIpAddress(HttpServletRequest request) {
        String xForwardedForHeader = request.getHeader("X-Forwarded-For");
        if (xForwardedForHeader != null && !xForwardedForHeader.isEmpty()) {
            return xForwardedForHeader.split(",")[0].trim();
        }

        String xRealIpHeader = request.getHeader("X-Real-IP");
        if (xRealIpHeader != null && !xRealIpHeader.isEmpty()) {
            return xRealIpHeader.trim();
        }

        return request.getRemoteAddr();
    }

    // New token for an expired (but correctly signed) one - this path is public in SecurityConfig
    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<usersAuthResponse>> refresh(
            @RequestHeader(value = "Authorization", required = false) String authorization) {
        return ResponseEntity.ok(ApiResponse.success(userService.refresh(authorization), "Token refreshed"));
    }

    // Checks the transaction PIN. A wrong PIN is a normal answer (valid=false), not an HTTP error,
    // so the app never mistakes it for an expired login.
    @PostMapping("/pin/verify")
    public ResponseEntity<ApiResponse<PinVerifyResponseDTO>> verifyPin(
            @CurrentUser AuthenticatedUser user,
            @RequestBody @Valid PinVerifyRequestDTO request) {
        boolean valid = userService.verifyPin(user.getUserId(), request.pin());
        return ResponseEntity.ok(new ApiResponse<>(valid, valid ? "PIN verified" : "Invalid PIN", new PinVerifyResponseDTO(valid)));
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserInformation>> me(@CurrentUser @NonNull AuthenticatedUser user) {
        UserInformation profile = userService.getMe(user.userId());
        return ResponseEntity.ok(ApiResponse.success(profile, "Profile retrieved"));
    }

    @GetMapping("/qr_me/{currencyCode}")
    public ResponseEntity<ApiResponse<UserQRInfo>> unwrapToken(@CurrentUser @NonNull AuthenticatedUser user, @PathVariable String currencyCode) {
        log.info("================ PROCESSING USER... ==================");
        // The whole QR bundle (identity + default-account zentag) is assembled
        // in the service: the zentag is NOT a JWT claim (JwtService only packs
        // identity fields), so it has to be read from the caller's default
        // fiat account rather than from AuthenticatedUser.
        UserQRInfo info = userService.getQRInfo(user.getUserId(), currencyCode);

        log.info("================ SENDING THE DATA BACK TO FRONTED... ==================");
        return ResponseEntity.ok(ApiResponse.success(info, "Profile retrieved"));
    }

    @PatchMapping({"/update"})
    public ResponseEntity<ApiResponse<UserDTO>> updateMe(@CurrentUser AuthenticatedUser user,
                                                         @RequestBody UserProfileUpdateRequest request) {
        UserDTO updated = userService.updateMe(user.getUserId(), request);
        return ResponseEntity.ok(ApiResponse.success(updated, "Profile updated"));
    }

    @GetMapping("/me/profile")
    public ResponseEntity<ApiResponse<UserProfileDTO>> getKycProfile(@CurrentUser AuthenticatedUser user) {
        UserProfileDTO profile = userService.getKycProfile(user.getUserId());
        return ResponseEntity.ok(ApiResponse.success(profile, "KYC profile retrieved"));
    }

}