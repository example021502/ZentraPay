package com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.dto.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.service.BillProvidersService;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.AuthenticatedUser;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.CurrentUser;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Bill Providers & Bill Payments — API_CONTRACT.md §8.
 */
@RestController
@RequestMapping("/api/bill-providers")
@RequiredArgsConstructor
public class BillProvidersController {

    private final BillProvidersService billProvidersService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<BillProviderDTO>>> listProviders(
            @RequestParam(required = false) String countryCode,
            @RequestParam(required = false) String categoryCode) {
        return ResponseEntity.ok(ApiResponse.success(
                billProvidersService.listProviders(countryCode, categoryCode), "Bill providers retrieved"));
    }

    @PostMapping("/validate")
    public ResponseEntity<ApiResponse<ValidateResponseDTO>> validate(@Valid @RequestBody ValidateRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(billProvidersService.validate(request), "Validation completed"));
    }

    @PostMapping("/pay")
    public ResponseEntity<ApiResponse<PayResponseDTO>> pay(@CurrentUser AuthenticatedUser user,
                                                            @Valid @RequestBody PayRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(billProvidersService.pay(user.userId(), request), "Bill payment processed"));
    }

    @GetMapping("/history")
    public ResponseEntity<ApiResponse<List<BillPaymentHistoryDTO>>> history(@CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(billProvidersService.history(user.userId()), "Bill payment history retrieved"));
    }
}
