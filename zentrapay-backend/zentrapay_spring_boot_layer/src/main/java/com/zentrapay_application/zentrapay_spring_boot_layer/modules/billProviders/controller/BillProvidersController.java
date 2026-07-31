package com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.dtos.BillProvidersResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.services.BillProvidersServices;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Bill Providers Controller - unified catalog for cards/service-providers/bills
 * (Pay bills: airtime, data, utilities, TV subscriptions)
 */
@RestController
@RequestMapping("/api/bill-providers")
@RequiredArgsConstructor
public class BillProvidersController {

    private final BillProvidersServices billProvidersServices;

    /**
     * Get all bill providers.
     */
    @GetMapping
    public ResponseEntity<ApiResponse<BillProvidersResponseDTO>> getAllProviders() {
        BillProvidersResponseDTO providers = billProvidersServices.getAllBillProviders();
        return ResponseEntity.ok(ApiResponse.success(providers, "Bill providers retrieved"));
    }

    /**
     * Get bill providers by category.
     */
    @GetMapping("/category/{category}")
    public ResponseEntity<ApiResponse<BillProvidersResponseDTO>> getProvidersByCategory(@PathVariable String category) {
        BillProvidersResponseDTO providers = billProvidersServices.getProvidersByCategory(category);
        return ResponseEntity.ok(ApiResponse.success(providers, "Providers by category retrieved"));
    }

    /**
     * Pay a bill.
     */
    @PostMapping("/pay")
    public ResponseEntity<ApiResponse<Object>> payBill(@RequestBody Map<String, Object> request) {
        // TODO: Implement bill payment logic
        return ResponseEntity.ok(ApiResponse.success(null, "Bill payment processed"));
    }

    /**
     * Validate a bill payment.
     */
    @PostMapping("/validate")
    public ResponseEntity<ApiResponse<Object>> validateBill(@RequestBody Map<String, Object> request) {
        // TODO: Implement bill validation
        return ResponseEntity.ok(ApiResponse.success(null, "Bill validation completed"));
    }

    /**
     * Get payment history for a specific provider.
     */
    @GetMapping("/history/{providerId}")
    public ResponseEntity<ApiResponse<Object>> getPaymentHistory(@PathVariable String providerId) {
        // TODO: Implement payment history retrieval
        return ResponseEntity.ok(ApiResponse.success(null, "Payment history retrieved"));
    }
}