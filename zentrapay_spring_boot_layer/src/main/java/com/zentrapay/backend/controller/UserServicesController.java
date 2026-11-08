package com.zentrapay.backend.controller;

import com.zentrapay.backend.dto.common.ApiResponse;
import com.zentrapay.backend.dto.provider.UserServiceDTO;
import com.zentrapay.backend.security.AuthenticatedUser;
import com.zentrapay.backend.security.CurrentUser;
import com.zentrapay.backend.service.provider.UserServicesService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * The services the user added to their Home screen.
 * <pre>
 * GET    /api/user-services                          my services (bill providers and service providers)
 * POST   /api/user-services                          add one  {kind: BILL | SERVICE, providerId}
 * DELETE /api/user-services/{kind}/{providerId}      remove one
 * </pre>
 */
@RestController
@RequestMapping("/api/user-services")
@RequiredArgsConstructor
public class UserServicesController {

    private final UserServicesService userServicesService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<UserServiceDTO>>> list(@CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(userServicesService.list(user.getUserId()), "Your services"));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<UserServiceDTO>> add(@CurrentUser AuthenticatedUser user,
                                                           @Valid @RequestBody UserServiceDTO.AddRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                userServicesService.add(user.getUserId(), request.kind(), request.providerId()), "Service added"));
    }

    @DeleteMapping("/{kind}/{providerId}")
    public ResponseEntity<ApiResponse<Void>> remove(@CurrentUser AuthenticatedUser user, @PathVariable String kind,
                                                    @PathVariable UUID providerId) {
        userServicesService.remove(user.getUserId(), kind, providerId);
        return ResponseEntity.ok(ApiResponse.success(null, "Service removed"));
    }
}
