package com.zentrapay.backend.controller;

import com.zentrapay.backend.dto.bill.*;
import com.zentrapay.backend.dto.common.ApiResponse;
import com.zentrapay.backend.security.AuthenticatedUser;
import com.zentrapay.backend.security.CurrentUser;
import com.zentrapay.backend.service.bill.BillProvidersService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Bill providers and bill payments.
 * <pre>
 * GET  /api/bill-providers            bill provider directory (country of the signed-in user)
 * POST /api/bill-providers/validate   check a meter / smartcard / phone number before paying
 * POST /api/bill-providers/pay        pay a bill from the wallet
 * GET  /api/bill-providers/history    my recent bill payments
 * </pre>
 */
@RestController
@RequestMapping("/api/bill-providers")
@RequiredArgsConstructor
public class BillProvidersController {

    private final BillProvidersService billProvidersService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<BillProviderDTO>>> listProviders(
            @CurrentUser AuthenticatedUser user,
            @RequestParam(required = false) String countryCode) {
        // The JWT country scopes the directory, so the app never has to send its own country
        return ResponseEntity.ok(ApiResponse.success(
                billProvidersService.listProviders(user, countryCode), "Bill providers retrieved"));
    }

    @PostMapping("/validate")
    public ResponseEntity<ApiResponse<ValidateResponseDTO>> validate(@Valid @RequestBody ValidateRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(billProvidersService.validate(request), "Validation completed"));
    }

    @PostMapping("/pay")
    public ResponseEntity<ApiResponse<PayResponseDTO>> pay(
            @CurrentUser AuthenticatedUser user,
            @Valid @RequestBody PayRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(billProvidersService.pay(user.getUserId(), request), "Bill payment processed"));
    }

    @GetMapping("/history")
    public ResponseEntity<ApiResponse<List<BillPaymentHistoryDTO>>> history(@CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(billProvidersService.history(user.getUserId()), "Bill payment history retrieved"));
    }
}
