package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.Datatypes;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.service.UsersService;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.AuthenticatedUser;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.CurrentUser;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

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

        // Comment: Extract the client IP address considering potential reverse proxies
        String ipAddress = getClientIpAddress(req);

        // Comment: Register user and pass the captured IP address for consent tracking
        usersAuthResponse userData = userService.register(request, ipAddress);

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

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserInformation>> me(@CurrentUser AuthenticatedUser user) {
        UserInformation profile = userService.getMe(user.userId());
        return ResponseEntity.ok(ApiResponse.success(profile, "Profile retrieved"));
    }
    @GetMapping("/qr_me")
    public ResponseEntity<ApiResponse<UserQRInfo>> unwrapToken(@CurrentUser AuthenticatedUser user) {
        log.info("================ PROCESSING USER... ==================");
        // The whole QR bundle (identity + default-account zentag) is assembled
        // in the service: the zentag is NOT a JWT claim (JwtService only packs
        // identity fields), so it has to be read from the caller's default
        // fiat account rather than from AuthenticatedUser.
        UserQRInfo info = userService.getQRInfo(user.getUserId());

        log.info("================ SENDING THE DATA BACK TO FRONTED... ==================");
        return ResponseEntity.ok(ApiResponse.success(info, "Profile retrieved"));
    }

    @PatchMapping("/update")
    public ResponseEntity<ApiResponse<UserDTO>> updateMe(@CurrentUser AuthenticatedUser user,
                                                                  @RequestBody UserMeUpdateDTO request) {
        UserDTO updated = userService.updateMe(user.getUserId(), request);
        return ResponseEntity.ok(ApiResponse.success(updated, "Profile updated"));
    }

    @GetMapping("/me/profile")
    public ResponseEntity<ApiResponse<UserProfileDTO>> getKycProfile(@CurrentUser AuthenticatedUser user) {
        UserProfileDTO profile = userService.getKycProfile(user.getUserId());
        return ResponseEntity.ok(ApiResponse.success(profile, "KYC profile retrieved"));
    }

    @PutMapping("/me/profile")
    public ResponseEntity<ApiResponse<UserProfileDTO>> upsertKycProfile(@CurrentUser AuthenticatedUser user,
                                                                                 @RequestBody UserProfileUpdateDTO request) {
        UserProfileDTO profile = userService.upsertKycProfile(user.getUserId(), request);
        return ResponseEntity.ok(ApiResponse.success(profile, "KYC profile updated"));
    }

//    @GetMapping("/me/receive")
//    public ResponseEntity<ApiResponse<ReceiveInfoDTO>> getReceiveInfo(@CurrentUser AuthenticatedUser user) {
//        ReceiveInfoDTO info = userService.getReceiveInfo(user.userId());
//        return ResponseEntity.ok(ApiResponse.success(info, "Receive info retrieved"));
//    }
//
//    @GetMapping("/me/merchant-profile")
//    public ResponseEntity<ApiResponse<MerchantProfileDTO>> getMerchantProfile(@CurrentUser AuthenticatedUser user) {
//        MerchantProfileDTO profile = userService.getMerchantProfile(user.userId());
//        return ResponseEntity.ok(ApiResponse.success(profile, "Merchant profile retrieved"));
//    }
//
//    @PutMapping("/me/merchant-profile")
//    public ResponseEntity<ApiResponse<MerchantProfileDTO>> upsertMerchantProfile(@CurrentUser AuthenticatedUser user,
//                                                                                   @RequestBody MerchantProfileDTO request) {
//        MerchantProfileDTO profile = userService.upsertMerchantProfile(user.userId(), request);
//        return ResponseEntity.ok(ApiResponse.success(profile, "Merchant profile updated"));
//    }
}