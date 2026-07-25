package com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.controller;


import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.dtos.BillProvidersResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.services.BillProvidersServices;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;


@RestController
@RequestMapping("/api/billProviders")
@RequiredArgsConstructor
public class BillProvidersController {
    private final BillProvidersServices billProvidersServices;
    // Changed from @PostMapping to @GetMapping since fetching configuration
    // does not require mutating server state via a request body.
    @GetMapping("/getALL")
    public ResponseEntity<ApiResponse<BillProvidersResponseDTO>> getBillProviders() {
        System.out.println("[SPRING_CTRL] get supported currency accounts hit");
        BillProvidersResponseDTO billProviders = billProvidersServices.getAllBillProviders();
        return ResponseEntity.ok(ApiResponse.success(billProviders, "Fetch successfully"));
    }
}